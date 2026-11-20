import json
import os
import re
import secrets
import threading
import time
import webbrowser
from datetime import date, datetime
from decimal import Decimal
from http import cookies
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, unquote, urlparse

import psycopg2
from psycopg2 import pool
import sys

if getattr(sys, "frozen", False):
    BASE_DIR = sys._MEIPASS
    ENV_DIR = os.path.dirname(sys.executable)
else:
    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    ENV_DIR = BASE_DIR

SESSION_TTL = 8 * 3600
MAX_BODY = 1024 * 1024
ESTADOS = ("PENDIENTE", "EN PROCESO", "COMPLETADA", "CANCELADA")
ROLES_EDICION = ("ADMINISTRADOR", "SUPERVISOR")
ROLES_BORRADO = ("ADMINISTRADOR",)

def load_env():
    """Carga DATABASE_URL desde .env si no está definida en el entorno."""
    path = os.path.join(ENV_DIR, ".env")
    if not os.path.isfile(path):
        return
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, val = line.partition("=")
            os.environ.setdefault(key.strip(), val.strip().strip('"').strip("'"))


_pool = None
_pool_lock = threading.Lock()


class HttpError(Exception):
    def __init__(self, status, message):
        super().__init__(message)
        self.status = status
        self.message = message


def get_pool():
    global _pool
    with _pool_lock:
        if _pool is None:
            url = os.environ.get("DATABASE_URL", "").strip().strip('"').strip("'")
            # Si en el panel del hosting se pegó la línea entera (DATABASE_URL=...), se queda solo con la dirección
            if url.upper().startswith("DATABASE_URL="):
                url = url.split("=", 1)[1].strip().strip('"').strip("'")
            if not url:
                raise HttpError(500, "Falta la variable de entorno DATABASE_URL en el servidor.")
            _pool = pool.ThreadedConnectionPool(1, 8, dsn=url, connect_timeout=10)
        return _pool


class Tx:
    """Transacción: todo se confirma junto o se revierte junto."""

    ALLOWED = ("CALL ", "SELECT * FROM ")

    def __enter__(self):
        self.pool = get_pool()
        self.conn = self.pool.getconn()
        self.cur = self.conn.cursor()
        self.columns = []
        return self

    def q(self, sql, params=()):
        if not sql.startswith(self.ALLOWED):
            raise RuntimeError("Solo se permiten CALL y SELECT * FROM función")
        self.cur.execute(sql, params)
        if self.cur.description:
            self.columns = [d[0] for d in self.cur.description]
            return [dict(zip(self.columns, row)) for row in self.cur.fetchall()]
        self.columns = []
        return []

    def __exit__(self, exc_type, exc, tb):
        broken = False
        try:
            if exc_type is None:
                self.conn.commit()
            else:
                try:
                    self.conn.rollback()
                except Exception:
                    broken = True
            broken = broken or bool(self.conn.closed)
            if isinstance(exc, psycopg2.OperationalError):
                broken = True
        finally:
            try:
                self.cur.close()
            except Exception:
                pass
            self.pool.putconn(self.conn, close=broken)
        return False


def query(sql, params=()):
    with Tx() as tx:
        return tx.q(sql, params)


def pg_message(exc):
    """Mensaje exacto lanzado por PostgreSQL (RAISE EXCEPTION / triggers)."""
    diag = getattr(exc, "diag", None)
    msg = getattr(diag, "message_primary", None) if diag else None
    if msg:
        return msg
    text = str(exc).strip()
    return text.splitlines()[0] if text else "Error de base de datos"


SESSIONS = {}
SESSIONS_LOCK = threading.Lock()
FAILS = {}
FAILS_LOCK = threading.Lock()


def create_session(user):
    token = secrets.token_urlsafe(32)
    with SESSIONS_LOCK:
        now = time.time()
        for k in [k for k, v in SESSIONS.items() if v["exp"] < now]:
            del SESSIONS[k]
        SESSIONS[token] = {"user": user, "exp": now + SESSION_TTL}
    return token


def get_session(token):
    if not token:
        return None
    with SESSIONS_LOCK:
        s = SESSIONS.get(token)
        if not s or s["exp"] < time.time():
            SESSIONS.pop(token, None)
            return None
        return s["user"]


def drop_session(token):
    with SESSIONS_LOCK:
        SESSIONS.pop(token, None)


def login_locked(key):
    with FAILS_LOCK:
        now = time.time()
        FAILS[key] = [t for t in FAILS.get(key, []) if now - t < 300]
        return len(FAILS[key]) >= 5


def login_failed(key):
    with FAILS_LOCK:
        FAILS.setdefault(key, []).append(time.time())


def text_field(body, key, label, max_len, required=True):
    val = body.get(key)
    val = "" if val is None else str(val).strip()
    if required and not val:
        raise HttpError(400, f"El campo «{label}» es obligatorio.")
    if len(val) > max_len:
        raise HttpError(400, f"El campo «{label}» admite como máximo {max_len} caracteres.")
    return val


def new_code(body):
    val = str(body.get("codigo") or "").strip().upper()
    if not re.fullmatch(r"[A-Z0-9_-]{1,6}", val):
        raise HttpError(400, "El código debe tener de 1 a 6 caracteres (letras, números, guion).")
    return val


def path_code(raw):
    val = unquote(raw).strip()
    if not val or len(val) > 10:
        raise HttpError(400, "Código no válido.")
    return val


def parse_date(raw, label):
    if not raw:
        return None
    try:
        return date.fromisoformat(raw).isoformat()
    except ValueError:
        raise HttpError(400, f"La fecha «{label}» no es válida (AAAA-MM-DD).")


def parse_estado(raw, required=False):
    val = (raw or "").strip().upper()
    if not val and not required:
        return None
    if val not in ESTADOS:
        raise HttpError(400, "Estado no válido.")
    return val


def parse_items(lista, etiqueta, con_horas):
    if lista is None:
        return []
    if not isinstance(lista, list) or len(lista) > 200:
        raise HttpError(400, f"Lista de {etiqueta} no válida.")
    vistos, salida = set(), []
    for it in lista:
        if not isinstance(it, dict):
            raise HttpError(400, f"Elemento de {etiqueta} no válido.")
        cod = str(it.get("codigo") or "").strip()
        if not cod or len(cod) > 10:
            raise HttpError(400, f"Código de {etiqueta} no válido.")
        if cod in vistos:
            raise HttpError(400, f"El elemento {cod} está repetido en {etiqueta}.")
        vistos.add(cod)
        try:
            cant = int(it.get("cantidad"))
            horas = float(it.get("horas")) if con_horas else None
        except (TypeError, ValueError):
            raise HttpError(400, f"Cantidad u horas no válidas en {etiqueta}.")
        if cant <= 0 or (con_horas and (horas <= 0 or horas > 99999)):
            raise HttpError(400, f"Cantidad y horas deben ser mayores a cero en {etiqueta}.")
        salida.append((cod, cant, horas))
    return salida

ENTIDADES = {
    "persona": {
        "listar": "fn_listar_personas",
        "insertar": "sp_insertar_persona",
        "actualizar": "sp_actualizar_persona",
        "eliminar": "sp_eliminar_persona",
        "campos": [("especialidad", "Especialidad", 30)],
    },
    "maquinaria": {
        "listar": "fn_listar_maquinaria",
        "insertar": "sp_insertar_maquinaria",
        "actualizar": "sp_actualizar_maquinaria",
        "eliminar": "sp_eliminar_maquinaria",
        "campos": [("descripcion", "Descripción", 100)],
    },
    "materiales": {
        "listar": "fn_listar_materiales",
        "insertar": "sp_insertar_material",
        "actualizar": "sp_actualizar_material",
        "eliminar": "sp_eliminar_material",
        "campos": [
            ("codrepuesto", "Repuesto", 6),
            ("codfabricante", "Fabricante", 6),
            ("descripcion", "Descripción", 100),
        ],
    },
    "herramientas": {
        "listar": "fn_listar_herramientas",
        "insertar": "sp_insertar_herramienta",
        "actualizar": "sp_actualizar_herramienta",
        "eliminar": "sp_eliminar_herramienta",
        "campos": [("descripcion", "Descripción", 100)],
    },
}

REPORTES = [
    (1, "Órdenes por estado", "Cantidad y porcentaje de órdenes agrupadas por estado.", "rpt_ordenes_por_estado"),
    (2, "Órdenes con recursos asignados", "Cada orden con el total de personas, materiales, herramientas y maquinaria.", "rpt_ordenes_detalladas"),
    (3, "Horas hombre por especialidad", "Horas hombre trabajadas por especialidad.", "rpt_horas_hombre_por_especialidad"),
    (4, "Materiales más utilizados", "Top 10 de materiales por cantidad consumida.", "rpt_materiales_mas_usados"),
    (5, "Maquinaria por encargado", "Maquinaria asignada por encargado, con horas y órdenes.", "rpt_maquinaria_por_encargado"),
    (6, "Herramientas más utilizadas", "Top 10 de herramientas por horas de uso.", "rpt_herramientas_mas_usadas"),
    (7, "Órdenes por encargado", "Total de órdenes por encargado, desglosadas por estado.", "rpt_ordenes_por_encargado"),
    (8, "Consumo por fabricante", "Materiales consumidos agrupados por fabricante.", "rpt_consumo_por_fabricante"),
    (9, "Órdenes por mes", "Órdenes y horas hombre acumuladas por mes.", "rpt_ordenes_por_mes"),
    (10, "Recursos por orden", "Horas hombre, herramientas, maquinaria y materiales por orden.", "rpt_recursos_por_orden"),
]

STATIC = {
    "/index.html": ("index.html", "text/html; charset=utf-8", True),
    "/informe.html": ("informe.html", "text/html; charset=utf-8", True),
    "/login.html": ("login.html", "text/html; charset=utf-8", False),
    "/styles.css": ("styles.css", "text/css; charset=utf-8", False),
    "/app.js": ("app.js", "application/javascript; charset=utf-8", False),
}

CSP = "default-src 'self'; style-src 'self'; script-src 'self'; img-src 'self' data:; frame-ancestors 'none'"


def json_default(o):
    if isinstance(o, Decimal):
        return int(o) if o == o.to_integral_value() else float(o)
    if isinstance(o, (date, datetime)):
        return o.isoformat()
    raise TypeError(f"No serializable: {type(o)}")


class Handler(BaseHTTPRequestHandler):
    server_version = "AppOrdenTrabajo/1.0"

    def log_message(self, fmt, *args):
        print("[%s] %s" % (self.log_date_time_string(), fmt % args))

    # ---- utilidades de respuesta ------------------------------------------
    def _send(self, status, body, ctype, extra=None):
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("Referrer-Policy", "same-origin")
        self.send_header("Cache-Control", "no-store")
        if ctype.startswith("text/html"):
            self.send_header("Content-Security-Policy", CSP)
        for k, v in extra or []:
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(body)

    def send_json(self, status, obj, extra=None):
        data = json.dumps(obj, default=json_default, ensure_ascii=False).encode("utf-8")
        self._send(status, data, "application/json; charset=utf-8", extra)

    def redirect(self, location):
        self.send_response(302)
        self.send_header("Location", location)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def read_json(self):
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            length = 0
        if length <= 0:
            return {}
        if length > MAX_BODY:
            raise HttpError(413, "La solicitud es demasiado grande.")
        try:
            data = json.loads(self.rfile.read(length).decode("utf-8"))
        except (ValueError, UnicodeDecodeError):
            raise HttpError(400, "El cuerpo de la solicitud no es JSON válido.")
        if not isinstance(data, dict):
            raise HttpError(400, "El cuerpo de la solicitud debe ser un objeto JSON.")
        return data

    def token(self):
        raw = self.headers.get("Cookie")
        if not raw:
            return None
        jar = cookies.SimpleCookie()
        try:
            jar.load(raw)
        except cookies.CookieError:
            return None
        morsel = jar.get("sid")
        return morsel.value if morsel else None

    def do_GET(self):
        self.dispatch("GET")

    def do_POST(self):
        self.dispatch("POST")

    def do_PUT(self):
        self.dispatch("PUT")

    def do_DELETE(self):
        self.dispatch("DELETE")

    def dispatch(self, method):
        url = urlparse(self.path)
        path = url.path
        try:
            if path.startswith("/api/"):
                self.api(method, path, parse_qs(url.query))
            elif method == "GET":
                self.static(path)
            else:
                raise HttpError(405, "Método no permitido.")
        except HttpError as e:
            self.send_json(e.status, {"error": e.message})
        except psycopg2.OperationalError:
            self.send_json(503, {"error": "No se pudo conectar con la base de datos. Verifique DATABASE_URL y su conexión."})
        except psycopg2.Error as e:
            self.send_json(400, {"error": pg_message(e)})
        except Exception as e:  # noqa: BLE001
            print("ERROR interno:", repr(e))
            self.send_json(500, {"error": "Error interno del servidor."})

    def static(self, path):
        if path in ("/", ""):
            path = "/index.html"
        if path == "/favicon.ico":
            return self._send(204, b"", "image/x-icon")
        entry = STATIC.get(path)
        if not entry:
            raise HttpError(404, "No encontrado.")
        fname, ctype, protegido = entry
        if protegido and not get_session(self.token()):
            return self.redirect("/login.html")
        full = os.path.join(BASE_DIR, fname)
        if not os.path.isfile(full):
            raise HttpError(404, f"Falta el archivo {fname}.")
        with open(full, "rb") as fh:
            self._send(200, fh.read(), ctype)

    def api(self, method, path, qs):
        parts = [p for p in path.split("/") if p]  # ['api', recurso, ...]
        recurso = parts[1] if len(parts) > 1 else ""

        if recurso == "login" and method == "POST":
            return self.h_login()
        if recurso == "logout" and method == "POST":
            drop_session(self.token())
            return self.send_json(200, {"ok": True}, [("Set-Cookie", "sid=; Path=/; Max-Age=0; HttpOnly; SameSite=Strict")])

        user = get_session(self.token())
        if not user:
            raise HttpError(401, "Sesión no válida o expirada.")

        if recurso == "me" and method == "GET":
            return self.send_json(200, user)
        if recurso == "catalogos" and method == "GET":
            return self.h_catalogos()
        if recurso == "siguiente-codigo" and method == "GET":
            return self.h_siguiente(qs)
        if recurso in ENTIDADES:
            return self.h_entidad(method, recurso, parts, qs, user)
        if recurso == "ordenes":
            return self.h_ordenes(method, parts, qs, user)
        if recurso == "informe" and method == "GET":
            return self.h_informe(qs)
        if recurso == "reportes" and method == "GET":
            return self.h_reportes(parts, qs)
        raise HttpError(404, "Recurso no encontrado.")

    @staticmethod
    def require(user, roles, accion):
        if user["rol"] not in roles:
            raise HttpError(403, f"Su rol ({user['rol']}) no tiene permiso para {accion}.")

    def h_login(self):
        body = self.read_json()
        username = str(body.get("username") or "").strip()
        password = str(body.get("password") or "")
        if not username or not password:
            raise HttpError(400, "Ingrese usuario y contraseña.")
        key = (self.client_address[0], username.lower())
        if login_locked(key):
            raise HttpError(429, "Demasiados intentos fallidos. Espere unos minutos.")
        rows = query("SELECT * FROM fn_login_usuario(%s::varchar, %s::varchar)", (username, password))
        if not rows:
            login_failed(key)
            raise HttpError(401, "Usuario o contraseña incorrectos.")
        u = rows[0]
        user = {"cod_usuario": u["cod_usuario"], "username": u["username"], "rol": u["rol"]}
        token = create_session(user)
        cookie = f"sid={token}; Path=/; Max-Age={SESSION_TTL}; HttpOnly; SameSite=Strict"
        self.send_json(200, user, [("Set-Cookie", cookie)])

    def h_catalogos(self):
        with Tx() as tx:
            data = {
                "encargados": tx.q("SELECT * FROM fn_listar_encargados()"),
                "repuestos": tx.q("SELECT * FROM fn_listar_repuestos()"),
                "fabricantes": tx.q("SELECT * FROM fn_listar_fabricantes()"),
                "personas": tx.q("SELECT * FROM fn_listar_personas(NULL::text)"),
                "maquinaria": tx.q("SELECT * FROM fn_listar_maquinaria(NULL::text)"),
                "herramientas": tx.q("SELECT * FROM fn_listar_herramientas(NULL::text)"),
                "materiales": tx.q("SELECT * FROM fn_listar_materiales(NULL::text)"),
            }
        data["estados"] = list(ESTADOS)
        self.send_json(200, data)

    def h_siguiente(self, qs):
        tipo = (qs.get("tipo") or [""])[0]
        if tipo not in ENTIDADES:
            raise HttpError(400, "Tipo no válido.")
        rows = query("SELECT * FROM fn_siguiente_codigo(%s::varchar)", (tipo,))
        self.send_json(200, {"codigo": list(rows[0].values())[0]})

    def h_entidad(self, method, key, parts, qs, user):
        cfg = ENTIDADES[key]
        n = len(parts)
        if method == "GET" and n == 2:
            q = ((qs.get("q") or [""])[0]).strip()
            rows = query(f"SELECT * FROM {cfg['listar']}(%s::text)", (q or None,))
            return self.send_json(200, rows)

        if method == "POST" and n == 2:
            self.require(user, ROLES_EDICION, "registrar")
            body = self.read_json()
            cod = new_code(body)
            valores = [text_field(body, k, lbl, mx) for k, lbl, mx in cfg["campos"]]
            marcas = ", ".join(["%s::varchar"] * (1 + len(valores)))
            query(f"CALL {cfg['insertar']}({marcas})", [cod, *valores])
            return self.send_json(201, {"ok": True, "codigo": cod})

        if method == "PUT" and n == 3:
            self.require(user, ROLES_EDICION, "editar")
            cod = path_code(parts[2])
            body = self.read_json()
            valores = [text_field(body, k, lbl, mx) for k, lbl, mx in cfg["campos"]]
            marcas = ", ".join(["%s::varchar"] * (1 + len(valores)))
            query(f"CALL {cfg['actualizar']}({marcas})", [cod, *valores])
            return self.send_json(200, {"ok": True})

        if method == "DELETE" and n == 3:
            self.require(user, ROLES_BORRADO, "eliminar")
            cod = path_code(parts[2])
            query(f"CALL {cfg['eliminar']}(%s::varchar)", (cod,))
            return self.send_json(200, {"ok": True})

        raise HttpError(404, "Operación no encontrada.")

    def h_ordenes(self, method, parts, qs, user):
        n = len(parts)
        if method == "GET" and n == 2:
            q = ((qs.get("q") or [""])[0]).strip()
            estado = parse_estado((qs.get("estado") or [""])[0])
            rows = query("SELECT * FROM fn_listar_ordenes(%s::text, %s::text)", (q or None, estado))
            return self.send_json(200, rows)

        if method == "POST" and n == 2:
            self.require(user, ROLES_EDICION, "crear órdenes")
            body = self.read_json()
            enc = text_field(body, "codencargado", "Encargado", 6)
            desc = text_field(body, "descripcion", "Descripción", 200)
            fecha = parse_date(str(body.get("fecha") or ""), "Fecha")
            if not fecha:
                raise HttpError(400, "El campo «Fecha» es obligatorio.")
            estado = parse_estado(str(body.get("estado") or "PENDIENTE"), required=True)
            personas = parse_items(body.get("personas"), "personas", True)
            materiales = parse_items(body.get("materiales"), "materiales", False)
            herramientas = parse_items(body.get("herramientas"), "herramientas", True)
            maquinaria = parse_items(body.get("maquinaria"), "maquinaria", True)
            if not (personas or materiales or herramientas or maquinaria):
                raise HttpError(400, "Asigne al menos un recurso (persona, material, herramienta o maquinaria).")
            with Tx() as tx:
                doc = list(tx.q("SELECT * FROM fn_siguiente_codigo_orden()")[0].values())[0]
                tx.q("CALL sp_crear_orden(%s::varchar, %s::varchar, %s::varchar, %s::date, %s::varchar)",
                     (doc, enc, desc, fecha, estado))
                for cod, cant, horas in personas:
                    tx.q("CALL sp_agregar_det_persona(%s::varchar, %s::varchar, %s::numeric, %s::integer)", (doc, cod, horas, cant))
                for cod, cant, _ in materiales:
                    tx.q("CALL sp_agregar_det_material(%s::varchar, %s::varchar, %s::integer)", (doc, cod, cant))
                for cod, cant, horas in herramientas:
                    tx.q("CALL sp_agregar_det_herramienta(%s::varchar, %s::varchar, %s::numeric, %s::integer)", (doc, cod, horas, cant))
                for cod, cant, horas in maquinaria:
                    tx.q("CALL sp_agregar_det_maquinaria(%s::varchar, %s::varchar, %s::numeric, %s::integer)", (doc, cod, horas, cant))
            return self.send_json(201, {"ok": True, "coddocumento": doc})

        if method == "PUT" and n == 4 and parts[3] == "estado":
            self.require(user, ROLES_EDICION, "cambiar el estado de órdenes")
            cod = path_code(parts[2])
            estado = parse_estado(str(self.read_json().get("estado") or ""), required=True)
            query("CALL sp_actualizar_estado_orden(%s::varchar, %s::varchar)", (cod, estado))
            return self.send_json(200, {"ok": True})

        raise HttpError(404, "Operación no encontrada.")

    def h_informe(self, qs):
        cod = ((qs.get("cod") or [""])[0]).strip()
        if not cod or len(cod) > 10:
            raise HttpError(400, "Código de orden no válido.")
        with Tx() as tx:
            cab = tx.q("SELECT * FROM fn_informe_cabecera(%s::varchar)", (cod,))
            if not cab:
                raise HttpError(404, f"La orden {cod} no existe.")
            data = {
                "cabecera": cab[0],
                "personas": tx.q("SELECT * FROM fn_informe_personas(%s::varchar)", (cod,)),
                "materiales": tx.q("SELECT * FROM fn_informe_materiales(%s::varchar)", (cod,)),
                "herramientas": tx.q("SELECT * FROM fn_informe_herramientas(%s::varchar)", (cod,)),
                "maquinaria": tx.q("SELECT * FROM fn_informe_maquinaria(%s::varchar)", (cod,)),
            }
        self.send_json(200, data)

    def h_reportes(self, parts, qs):
        if len(parts) == 2:
            return self.send_json(200, [{"id": i, "titulo": t, "descripcion": d} for i, t, d, _ in REPORTES])
        try:
            rid = int(parts[2])
        except ValueError:
            raise HttpError(400, "Reporte no válido.")
        rep = next((r for r in REPORTES if r[0] == rid), None)
        if not rep:
            raise HttpError(404, "Reporte no encontrado.")
        desde = parse_date((qs.get("desde") or [""])[0], "Desde")
        hasta = parse_date((qs.get("hasta") or [""])[0], "Hasta")
        if desde and hasta and desde > hasta:
            raise HttpError(400, "La fecha «Desde» no puede ser mayor que «Hasta».")
        estado = parse_estado((qs.get("estado") or [""])[0])
        with Tx() as tx:
            rows = tx.q(f"SELECT * FROM {rep[3]}(%s::date, %s::date, %s::text)", (desde, hasta, estado))
            cols = list(tx.columns)
        self.send_json(200, {"id": rid, "titulo": rep[1], "columns": cols, "rows": rows})


def main():
    load_env()
    host = os.environ.get("HOST", "127.0.0.1")
    port = int(os.environ.get("PORT", "8000"))
    if not os.environ.get("DATABASE_URL"):
        print("AVISO: DATABASE_URL no está definida; la API responderá con error hasta configurarla.")
    httpd = ThreadingHTTPServer((host, port), Handler)
    url = f"http://{'localhost' if host == '127.0.0.1' else host}:{port}/"
    print(f"AppOrdenTrabajo en {url}  (Ctrl+C para detener)")
    if os.environ.get("NO_BROWSER") != "1":
        threading.Timer(1.0, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
    finally:
        httpd.server_close()


if __name__ == "__main__":
    main()
