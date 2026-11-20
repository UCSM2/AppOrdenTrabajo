--CREAR TABLAS Y RELACIONES
CREATE TABLE Fabricante (
    CodFabricante CHAR(6),
    CONSTRAINT PK_Fabricante PRIMARY KEY (CodFabricante)
);

CREATE TABLE Repuesto (
    CodRepuesto CHAR(6),
    CONSTRAINT PK_Repuesto PRIMARY KEY (CodRepuesto)
);

CREATE TABLE Encargado (
    CodEncargado CHAR(6),
    Nombre VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Encargado PRIMARY KEY (CodEncargado)
);

CREATE TABLE Maquinaria (
    CodMaquinaria CHAR(6),
    DescripcionMaquinaria VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Maquinaria PRIMARY KEY (CodMaquinaria)
);

CREATE TABLE Persona (
    CodPersona CHAR(6),
    Especialidad VARCHAR(30) NOT NULL,
    CONSTRAINT PK_Persona PRIMARY KEY (CodPersona)
);

CREATE TABLE Herramientas (
    CodHerramientas CHAR(6),
    DescripcionHerramientas VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Herramientas PRIMARY KEY (CodHerramientas)
);

CREATE TABLE Materiales (
    CodMateriales CHAR(6),
    CodRepuesto CHAR(6) NOT NULL,
    CodFabricante CHAR(6) NOT NULL,
    DescripcionMateriales VARCHAR(100) NOT NULL,
    CONSTRAINT PK_Materiales PRIMARY KEY (CodMateriales),
    CONSTRAINT FK_Materiales_Repuesto FOREIGN KEY (CodRepuesto) REFERENCES Repuesto(CodRepuesto),
    CONSTRAINT FK_Materiales_Fabricante FOREIGN KEY (CodFabricante) REFERENCES Fabricante(CodFabricante)
);

CREATE TABLE CabeceraOrdenTrabajo (
    CodDocumento VARCHAR(10),
    CodEncargado CHAR(6) NOT NULL,
    DescripcionDocumento VARCHAR(200) NOT NULL,
    Fecha DATE NOT NULL,
    Estado VARCHAR(20) NOT NULL,
    CONSTRAINT PK_CabeceraOrdenTrabajo PRIMARY KEY (CodDocumento),
    CONSTRAINT FK_Cabecera_Encargado FOREIGN KEY (CodEncargado) REFERENCES Encargado(CodEncargado)
);

CREATE TABLE DetallePersona (
    CodDocumento VARCHAR(10),
    CodPersona CHAR(6),
    HorasPersona NUMERIC(4,2) NOT NULL,
    CantidadPersonas INTEGER NOT NULL,
    CONSTRAINT PK_DetallePersona PRIMARY KEY (CodDocumento, CodPersona),
    CONSTRAINT FK_DetallePersona_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetallePersona_Persona FOREIGN KEY (CodPersona) REFERENCES Persona(CodPersona)
);

CREATE TABLE DetalleHerramientas (
    CodDocumento VARCHAR(10),
    CodHerramientas CHAR(6),
    CantidadHerramientas INTEGER NOT NULL,
    HorasHerramientas NUMERIC(4,2) NOT NULL,
    CONSTRAINT PK_DetalleHerramientas PRIMARY KEY (CodDocumento, CodHerramientas),
    CONSTRAINT FK_DetalleHerramientas_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetalleHerramientas_Herramientas FOREIGN KEY (CodHerramientas) REFERENCES Herramientas(CodHerramientas)
);

CREATE TABLE DetalleMaquinaria (
    CodDocumento VARCHAR(10),
    CodMaquinaria CHAR(6),
    HorasMaquinaria NUMERIC(4,2) NOT NULL,
    CantidadMaquinaria INTEGER NOT NULL,
    CONSTRAINT PK_DetalleMaquinaria PRIMARY KEY (CodDocumento, CodMaquinaria),
    CONSTRAINT FK_DetalleMaquinaria_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetalleMaquinaria_Maquinaria FOREIGN KEY (CodMaquinaria) REFERENCES Maquinaria(CodMaquinaria)
);

CREATE TABLE DetalleMateriales (
    CodDocumento VARCHAR(10),
    CodMateriales CHAR(6),
    CantidadMateriales NUMERIC(5,2) NOT NULL,
    CONSTRAINT PK_DetalleMateriales PRIMARY KEY (CodDocumento, CodMateriales),
    CONSTRAINT FK_DetalleMateriales_Cabecera FOREIGN KEY (CodDocumento) REFERENCES CabeceraOrdenTrabajo(CodDocumento),
    CONSTRAINT FK_DetalleMateriales_Materiales FOREIGN KEY (CodMateriales) REFERENCES Materiales(CodMateriales)
);

--LOGIN
CREATE TABLE usuarios (
    cod_usuario SERIAL PRIMARY KEY,
    username VARCHAR(60) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol VARCHAR(30) NOT NULL DEFAULT 'OPERADOR',
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_creacion TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_usuario_rol
        CHECK (rol IN ('ADMINISTRADOR', 'SUPERVISOR', 'OPERADOR'))
);

CREATE INDEX idx_usuarios_username
ON usuarios(username);

--Indices Ordinarios
CREATE INDEX IDX_Cabecera_Fecha ON CabeceraOrdenTrabajo (Fecha);
CREATE INDEX IDX_Cabecera_Estado ON CabeceraOrdenTrabajo (Estado);
CREATE INDEX IDX_Persona_Especialidad ON Persona (Especialidad);
CREATE INDEX IDX_Materiales_Descripcion ON Materiales (DescripcionMateriales);

--INSERTAR DATOS A LA Tabla
INSERT INTO Fabricante (CodFabricante) VALUES 
('CADTEM'),
('SAE20 '), 
('ISO220'), 
('PE806T'),
('304L  '),
('CATERP'),
('KOMATS');

INSERT INTO Repuesto (CodRepuesto) VALUES 
('CADTEM'),
('SAE20 '),
('ISO220'),
('AM2238'),
('304L  '),
('REP001'),
('REP002');

INSERT INTO Encargado (CodEncargado, Nombre) VALUES 
('ENC001', 'ALEGRE, Paul'),
('ENC002', 'GOMEZ, Carlos');

INSERT INTO Maquinaria (CodMaquinaria, DescripcionMaquinaria) VALUES 
('MAQ001', 'Camión Minero Caterpillar 797F'),
('MAQ002', 'Excavadora Hidráulica Komatsu PC3000'),
('MAQ003', 'Montacargas Industrial Toyota 8FGU25'),
('MAQ004', 'Grúa Móvil Automotriz Grove GMK5250'),
('MAQ006', 'Operador de Maquinaria Pesada');

INSERT INTO Persona (CodPersona, Especialidad) VALUES 
('PER001', 'Técnico Instrumentista'),
('PER002', 'Serv. Ext. Confiabilidad'),
('PER003', 'Servicios Externos - Chancado'),
('PER004', 'Técnico Mecánico Chancado'),
('PER005', 'Servicio Lubricacion'),
('PER006', 'Operador de Maquinaria Pesada');

INSERT INTO Herramientas (CodHerramientas, DescripcionHerramientas) VALUES 
('HER001', 'Caja de herramientas básica MEI'),
('HER002', 'Caja de herramientas Mecánica'),
('HER003', 'Equipo de Alineación Láser');

INSERT INTO Materiales (CodMateriales, CodRepuesto, CodFabricante, DescripcionMateriales) VALUES 
('MAT001', 'CADTEM', 'CADTEM', 'Cadena TEM 27'),
('MAT002', 'SAE20 ', 'SAE20 ', 'Lubricante SAE20'),
('MAT003', 'ISO220', 'ISO220', 'Aceite ISO VG220'),
('MAT004', 'AM2238', 'PE806T', 'MANGAS PLISADAS FILTRANTES DE POLIESTER CON TRATAMIENTO OLEO E HIDROFOBICO. Ø160 X L2.030mm'),
('MAT005', '304L  ', '304L  ', 'CANASTILLOS DE ACERO INOXIDABLE 304L Ø152 X L2050mm'),
('MAT006', 'REP001', 'CATERP', 'Filtro de Aire Primario para Motor Pesado Cat');

INSERT INTO CabeceraOrdenTrabajo (CodDocumento, CodEncargado, DescripcionDocumento, Fecha, Estado) VALUES 
('DOC0000001', 'ENC001', '6M/D INS INST FILTRO AIRE FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000002', 'ENC001', '6M/D PREV MECA FILTRO AIRE FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000003', 'ENC001', '6M/D C/O MECA MANGAS FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000004', 'ENC001', '1M/D PREV MECA FILTRO AIRE FL001(_)', '2021-07-21', 'Aprobado'),
('DOC0000005', 'ENC002', 'MANTENIMIENTO CORRECTIVO DE CELDAS DE FLOTACIÓN', '2021-07-22', 'En Proceso'); 

INSERT INTO DetallePersona (CodDocumento, CodPersona, HorasPersona, CantidadPersonas) VALUES 
('DOC0000001', 'PER001', 8.00, 2),
('DOC0000002', 'PER002', 1.00, 1),
('DOC0000002', 'PER003', 36.00, 2),
('DOC0000002', 'PER004', 3.00, 2),
('DOC0000002', 'PER005', 2.50, 1),
('DOC0000003', 'PER003', 18.00, 2),
('DOC0000004', 'PER002', 1.00, 1),
('DOC0000004', 'PER004', 3.00, 2),
('DOC0000004', 'PER005', 1.00, 1),
('DOC0000005', 'PER006', 12.00, 1);

INSERT INTO DetalleHerramientas (CodDocumento, CodHerramientas, CantidadHerramientas, HorasHerramientas) VALUES 
('DOC0000001', 'HER001', 1, 4.00),
('DOC0000002', 'HER002', 5, 4.87),
('DOC0000003', 'HER002', 3, 3.00),
('DOC0000004', 'HER002', 1, 1.50),
('DOC0000005', 'HER003', 1, 6.50);

INSERT INTO DetalleMaquinaria (CodDocumento, CodMaquinaria, HorasMaquinaria, CantidadMaquinaria) VALUES 
('DOC0000002', 'MAQ003', 4.50, 1), 
('DOC0000003', 'MAQ004', 6.00, 1), 
('DOC0000005', 'MAQ002', 10.00, 1);

INSERT INTO DetalleMateriales (CodDocumento, CodMateriales, CantidadMateriales) VALUES 
('DOC0000002', 'MAT001', 1.00),
('DOC0000002', 'MAT002', 0.25),
('DOC0000002', 'MAT003', 5.00),
('DOC0000002', 'MAT004', 152.00),
('DOC0000002', 'MAT005', 152.00),
('DOC0000003', 'MAT004', 152.00),
('DOC0000004', 'MAT002', 0.25),
('DOC0000005', 'MAT006', 2.00);


--TRIGERRS
CREATE OR REPLACE FUNCTION proteger_recurso_asignado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    existe_asignacion BOOLEAN := FALSE;
    codigo_recurso CHAR(6);
BEGIN

    IF TG_TABLE_NAME = 'persona' THEN

        codigo_recurso := OLD.CodPersona;

        SELECT EXISTS (
            SELECT 1
            FROM DetallePersona d
            INNER JOIN CabeceraOrdenTrabajo ot
                ON ot.CodDocumento = d.CodDocumento
            WHERE d.CodPersona = codigo_recurso
              AND UPPER(ot.Estado) NOT IN ('COMPLETADA', 'FINALIZADA', 'CANCELADA')
        ) INTO existe_asignacion;

    ELSIF TG_TABLE_NAME = 'herramientas' THEN

        codigo_recurso := OLD.CodHerramientas;

        SELECT EXISTS (
            SELECT 1
            FROM DetalleHerramientas d
            INNER JOIN CabeceraOrdenTrabajo ot
                ON ot.CodDocumento = d.CodDocumento
            WHERE d.CodHerramientas = codigo_recurso
              AND UPPER(ot.Estado) NOT IN ('COMPLETADA', 'FINALIZADA', 'CANCELADA')
        ) INTO existe_asignacion;

    ELSIF TG_TABLE_NAME = 'maquinaria' THEN

        codigo_recurso := OLD.CodMaquinaria;

        SELECT EXISTS (
            SELECT 1
            FROM DetalleMaquinaria d
            INNER JOIN CabeceraOrdenTrabajo ot
                ON ot.CodDocumento = d.CodDocumento
            WHERE d.CodMaquinaria = codigo_recurso
              AND UPPER(ot.Estado) NOT IN ('COMPLETADA', 'FINALIZADA', 'CANCELADA')
        ) INTO existe_asignacion;

    ELSIF TG_TABLE_NAME = 'materiales' THEN

        codigo_recurso := OLD.CodMateriales;

        SELECT EXISTS (
            SELECT 1
            FROM DetalleMateriales d
            INNER JOIN CabeceraOrdenTrabajo ot
                ON ot.CodDocumento = d.CodDocumento
            WHERE d.CodMateriales = codigo_recurso
              AND UPPER(ot.Estado) NOT IN ('COMPLETADA', 'FINALIZADA', 'CANCELADA')
        ) INTO existe_asignacion;

    ELSIF TG_TABLE_NAME = 'repuesto' THEN

        codigo_recurso := OLD.CodRepuesto;

        SELECT EXISTS (
            SELECT 1
            FROM DetalleMateriales d
            INNER JOIN Materiales m
                ON m.CodMateriales = d.CodMateriales
            INNER JOIN CabeceraOrdenTrabajo ot
                ON ot.CodDocumento = d.CodDocumento
            WHERE m.CodRepuesto = codigo_recurso
              AND UPPER(ot.Estado) NOT IN ('COMPLETADA', 'FINALIZADA', 'CANCELADA')
        ) INTO existe_asignacion;

    END IF;

    IF existe_asignacion THEN
        RAISE EXCEPTION
            'OPERACION DENEGADA: El recurso (%) esta asignado a una Orden de Trabajo activa.', TRIM(codigo_recurso)
            USING ERRCODE = '23503';
    END IF;

    IF TG_OP = 'UPDATE' THEN
        RETURN NEW;
    END IF;

    RETURN OLD;
END;
$$;


CREATE TRIGGER trg_proteger_persona
BEFORE DELETE ON Persona
FOR EACH ROW
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_herramientas
BEFORE DELETE ON Herramientas
FOR EACH ROW
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_maquinaria
BEFORE DELETE ON Maquinaria
FOR EACH ROW
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_repuesto
BEFORE DELETE ON Repuesto
FOR EACH ROW
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_materiales
BEFORE DELETE ON Materiales
FOR EACH ROW
EXECUTE FUNCTION proteger_recurso_asignado();


-- Borrado lógico
ALTER TABLE Persona      ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE Maquinaria   ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE Materiales   ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE Herramientas ADD COLUMN IF NOT EXISTS activo BOOLEAN NOT NULL DEFAULT TRUE;

-- Homorgar estados para app
UPDATE CabeceraOrdenTrabajo SET Estado = 'COMPLETADA' WHERE Estado = 'Aprobado';
UPDATE CabeceraOrdenTrabajo SET Estado = 'EN PROCESO' WHERE Estado = 'En Proceso';

-- Triggers adicionales
CREATE TRIGGER trg_proteger_baja_persona
BEFORE UPDATE OF activo ON Persona
FOR EACH ROW WHEN (OLD.activo = TRUE AND NEW.activo = FALSE)
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_baja_herramientas
BEFORE UPDATE OF activo ON Herramientas
FOR EACH ROW WHEN (OLD.activo = TRUE AND NEW.activo = FALSE)
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_baja_maquinaria
BEFORE UPDATE OF activo ON Maquinaria
FOR EACH ROW WHEN (OLD.activo = TRUE AND NEW.activo = FALSE)
EXECUTE FUNCTION proteger_recurso_asignado();

CREATE TRIGGER trg_proteger_baja_materiales
BEFORE UPDATE OF activo ON Materiales
FOR EACH ROW WHEN (OLD.activo = TRUE AND NEW.activo = FALSE)
EXECUTE FUNCTION proteger_recurso_asignado();

-- Usuarios para iniciar sesion
INSERT INTO usuarios (username, password, rol, activo) VALUES
('admin',      'admin123', 'ADMINISTRADOR', TRUE),
('supervisor', 'super123', 'SUPERVISOR',    TRUE),
('operador',   'opera123', 'OPERADOR',      TRUE)
ON CONFLICT (username) DO NOTHING;
DROP FUNCTION IF EXISTS fn_login_usuario(VARCHAR, VARCHAR);

CREATE OR REPLACE FUNCTION fn_login_usuario(p_username VARCHAR, p_password VARCHAR)
RETURNS TABLE(cod_usuario INTEGER, username TEXT, rol TEXT)
LANGUAGE sql STABLE AS $$
    SELECT u.cod_usuario::integer, u.username::text, upper(u.rol)::text
    FROM usuarios u
    WHERE u.activo
      AND u.username = btrim(p_username)
      AND u.password = p_password
    LIMIT 1;
$$;

-- GENERADORES DE CÓDIGO
CREATE OR REPLACE FUNCTION fn_siguiente_codigo(p_tipo VARCHAR)
RETURNS VARCHAR
LANGUAGE plpgsql AS $$
DECLARE
    v_pref TEXT;
    v_max  INTEGER;
BEGIN
    CASE lower(btrim(p_tipo))
        WHEN 'persona' THEN
            v_pref := 'PER';
            SELECT COALESCE(MAX(substring(CodPersona::text FROM 4)::int), 0) INTO v_max
              FROM Persona WHERE CodPersona::text ~ '^PER[0-9]{3}$';
        WHEN 'maquinaria' THEN
            v_pref := 'MAQ';
            SELECT COALESCE(MAX(substring(CodMaquinaria::text FROM 4)::int), 0) INTO v_max
              FROM Maquinaria WHERE CodMaquinaria::text ~ '^MAQ[0-9]{3}$';
        WHEN 'materiales' THEN
            v_pref := 'MAT';
            SELECT COALESCE(MAX(substring(CodMateriales::text FROM 4)::int), 0) INTO v_max
              FROM Materiales WHERE CodMateriales::text ~ '^MAT[0-9]{3}$';
        WHEN 'herramientas' THEN
            v_pref := 'HER';
            SELECT COALESCE(MAX(substring(CodHerramientas::text FROM 4)::int), 0) INTO v_max
              FROM Herramientas WHERE CodHerramientas::text ~ '^HER[0-9]{3}$';
        ELSE
            RAISE EXCEPTION 'Tipo de código desconocido: %', p_tipo;
    END CASE;
    RETURN v_pref || lpad((v_max + 1)::text, 3, '0');
END $$;

CREATE OR REPLACE FUNCTION fn_siguiente_codigo_orden()
RETURNS VARCHAR
LANGUAGE plpgsql AS $$
DECLARE
    v_max INTEGER;
BEGIN
    PERFORM pg_advisory_xact_lock(7001);
    SELECT COALESCE(MAX(substring(CodDocumento::text FROM 4)::int), 0) INTO v_max
      FROM CabeceraOrdenTrabajo WHERE CodDocumento::text ~ '^DOC[0-9]{7}$';
    RETURN 'DOC' || lpad((v_max + 1)::text, 7, '0');
END $$;


-- FUNCIONES DE CONSULTA
CREATE OR REPLACE FUNCTION fn_listar_personas(p_buscar TEXT DEFAULT NULL)
RETURNS TABLE(codigo TEXT, especialidad TEXT)
LANGUAGE sql STABLE AS $$
    SELECT p.CodPersona::text, p.Especialidad::text
    FROM Persona p
    WHERE p.activo
      AND (COALESCE(btrim(p_buscar), '') = ''
           OR p.CodPersona::text ILIKE '%' || btrim(p_buscar) || '%'
           OR p.Especialidad     ILIKE '%' || btrim(p_buscar) || '%')
    ORDER BY p.CodPersona;
$$;

CREATE OR REPLACE FUNCTION fn_listar_maquinaria(p_buscar TEXT DEFAULT NULL)
RETURNS TABLE(codigo TEXT, descripcion TEXT)
LANGUAGE sql STABLE AS $$
    SELECT m.CodMaquinaria::text, m.DescripcionMaquinaria::text
    FROM Maquinaria m
    WHERE m.activo
      AND (COALESCE(btrim(p_buscar), '') = ''
           OR m.CodMaquinaria::text     ILIKE '%' || btrim(p_buscar) || '%'
           OR m.DescripcionMaquinaria   ILIKE '%' || btrim(p_buscar) || '%')
    ORDER BY m.CodMaquinaria;
$$;

CREATE OR REPLACE FUNCTION fn_listar_herramientas(p_buscar TEXT DEFAULT NULL)
RETURNS TABLE(codigo TEXT, descripcion TEXT)
LANGUAGE sql STABLE AS $$
    SELECT h.CodHerramientas::text, h.DescripcionHerramientas::text
    FROM Herramientas h
    WHERE h.activo
      AND (COALESCE(btrim(p_buscar), '') = ''
           OR h.CodHerramientas::text    ILIKE '%' || btrim(p_buscar) || '%'
           OR h.DescripcionHerramientas  ILIKE '%' || btrim(p_buscar) || '%')
    ORDER BY h.CodHerramientas;
$$;

CREATE OR REPLACE FUNCTION fn_listar_materiales(p_buscar TEXT DEFAULT NULL)
RETURNS TABLE(codigo TEXT, descripcion TEXT, codrepuesto TEXT, codfabricante TEXT)
LANGUAGE sql STABLE AS $$
    SELECT m.CodMateriales::text, m.DescripcionMateriales::text,
           r.CodRepuesto::text, f.CodFabricante::text
    FROM Materiales m
    JOIN Repuesto   r ON r.CodRepuesto   = m.CodRepuesto
    JOIN Fabricante f ON f.CodFabricante = m.CodFabricante
    WHERE m.activo
      AND (COALESCE(btrim(p_buscar), '') = ''
           OR m.CodMateriales::text      ILIKE '%' || btrim(p_buscar) || '%'
           OR m.DescripcionMateriales    ILIKE '%' || btrim(p_buscar) || '%'
           OR r.CodRepuesto::text        ILIKE '%' || btrim(p_buscar) || '%'
           OR f.CodFabricante::text      ILIKE '%' || btrim(p_buscar) || '%')
    ORDER BY m.CodMateriales;
$$;

CREATE OR REPLACE FUNCTION fn_listar_repuestos()
RETURNS TABLE(codigo TEXT)
LANGUAGE sql STABLE AS $$
    SELECT r.CodRepuesto::text FROM Repuesto r ORDER BY r.CodRepuesto;
$$;

CREATE OR REPLACE FUNCTION fn_listar_fabricantes()
RETURNS TABLE(codigo TEXT)
LANGUAGE sql STABLE AS $$
    SELECT f.CodFabricante::text FROM Fabricante f ORDER BY f.CodFabricante;
$$;

CREATE OR REPLACE FUNCTION fn_listar_encargados()
RETURNS TABLE(codigo TEXT, nombre TEXT)
LANGUAGE sql STABLE AS $$
    SELECT e.CodEncargado::text, e.Nombre::text FROM Encargado e ORDER BY e.Nombre;
$$;

CREATE OR REPLACE FUNCTION fn_listar_ordenes(p_buscar TEXT DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(coddocumento TEXT, descripcion TEXT, codencargado TEXT, encargado TEXT, fecha DATE, estado TEXT)
LANGUAGE sql STABLE AS $$
    SELECT c.CodDocumento::text, c.DescripcionDocumento::text, c.CodEncargado::text,
           e.Nombre::text, c.Fecha, c.Estado::text
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    WHERE (COALESCE(btrim(p_estado), '') = '' OR c.Estado = btrim(p_estado))
      AND (COALESCE(btrim(p_buscar), '') = ''
           OR c.CodDocumento::text     ILIKE '%' || btrim(p_buscar) || '%'
           OR c.DescripcionDocumento   ILIKE '%' || btrim(p_buscar) || '%'
           OR e.Nombre                 ILIKE '%' || btrim(p_buscar) || '%')
    ORDER BY c.Fecha DESC, c.CodDocumento DESC;
$$;

-- PROCEDIMIENTOS: PERSONA
CREATE OR REPLACE PROCEDURE sp_insertar_persona(p_cod VARCHAR, p_especialidad VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF v_cod = '' THEN RAISE EXCEPTION 'El código de la persona es obligatorio'; END IF;
    IF COALESCE(btrim(p_especialidad), '') = '' THEN RAISE EXCEPTION 'La especialidad es obligatoria'; END IF;
    IF EXISTS (SELECT 1 FROM Persona WHERE CodPersona = v_cod) THEN
        RAISE EXCEPTION 'Ya existe una persona con el código % (puede estar dada de baja)', v_cod;
    END IF;
    INSERT INTO Persona (CodPersona, Especialidad) VALUES (v_cod, btrim(p_especialidad));
END $$;

CREATE OR REPLACE PROCEDURE sp_actualizar_persona(p_cod VARCHAR, p_especialidad VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(btrim(p_especialidad), '') = '' THEN RAISE EXCEPTION 'La especialidad es obligatoria'; END IF;
    UPDATE Persona SET Especialidad = btrim(p_especialidad)
     WHERE CodPersona = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'La persona % no existe o está dada de baja', v_cod; END IF;
END $$;

CREATE OR REPLACE PROCEDURE sp_eliminar_persona(p_cod VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    UPDATE Persona SET activo = FALSE WHERE CodPersona = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'La persona % no existe o ya está dada de baja', v_cod; END IF;
END $$;

-- PROCEDIMIENTOS: MAQUINARIA
CREATE OR REPLACE PROCEDURE sp_insertar_maquinaria(p_cod VARCHAR, p_descripcion VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF v_cod = '' THEN RAISE EXCEPTION 'El código de la maquinaria es obligatorio'; END IF;
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción es obligatoria'; END IF;
    IF EXISTS (SELECT 1 FROM Maquinaria WHERE CodMaquinaria = v_cod) THEN
        RAISE EXCEPTION 'Ya existe una maquinaria con el código % (puede estar dada de baja)', v_cod;
    END IF;
    INSERT INTO Maquinaria (CodMaquinaria, DescripcionMaquinaria) VALUES (v_cod, btrim(p_descripcion));
END $$;

CREATE OR REPLACE PROCEDURE sp_actualizar_maquinaria(p_cod VARCHAR, p_descripcion VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción es obligatoria'; END IF;
    UPDATE Maquinaria SET DescripcionMaquinaria = btrim(p_descripcion)
     WHERE CodMaquinaria = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'La maquinaria % no existe o está dada de baja', v_cod; END IF;
END $$;

CREATE OR REPLACE PROCEDURE sp_eliminar_maquinaria(p_cod VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    UPDATE Maquinaria SET activo = FALSE WHERE CodMaquinaria = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'La maquinaria % no existe o ya está dada de baja', v_cod; END IF;
END $$;

-- PROCEDIMIENTOS: HERRAMIENTAS
CREATE OR REPLACE PROCEDURE sp_insertar_herramienta(p_cod VARCHAR, p_descripcion VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF v_cod = '' THEN RAISE EXCEPTION 'El código de la herramienta es obligatorio'; END IF;
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción es obligatoria'; END IF;
    IF EXISTS (SELECT 1 FROM Herramientas WHERE CodHerramientas = v_cod) THEN
        RAISE EXCEPTION 'Ya existe una herramienta con el código % (puede estar dada de baja)', v_cod;
    END IF;
    INSERT INTO Herramientas (CodHerramientas, DescripcionHerramientas) VALUES (v_cod, btrim(p_descripcion));
END $$;

CREATE OR REPLACE PROCEDURE sp_actualizar_herramienta(p_cod VARCHAR, p_descripcion VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción es obligatoria'; END IF;
    UPDATE Herramientas SET DescripcionHerramientas = btrim(p_descripcion)
     WHERE CodHerramientas = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'La herramienta % no existe o está dada de baja', v_cod; END IF;
END $$;

CREATE OR REPLACE PROCEDURE sp_eliminar_herramienta(p_cod VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    UPDATE Herramientas SET activo = FALSE WHERE CodHerramientas = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'La herramienta % no existe o ya está dada de baja', v_cod; END IF;
END $$;

-- PROCEDIMIENTOS: MATERIALES
CREATE OR REPLACE PROCEDURE sp_insertar_material(p_cod VARCHAR, p_codrepuesto VARCHAR,
                                                 p_codfabricante VARCHAR, p_descripcion VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
    v_rep TEXT := upper(btrim(COALESCE(p_codrepuesto, '')));
    v_fab TEXT := upper(btrim(COALESCE(p_codfabricante, '')));
BEGIN
    IF v_cod = '' THEN RAISE EXCEPTION 'El código del material es obligatorio'; END IF;
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción es obligatoria'; END IF;
    IF NOT EXISTS (SELECT 1 FROM Repuesto WHERE CodRepuesto = v_rep) THEN
        RAISE EXCEPTION 'El repuesto % no existe', v_rep;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Fabricante WHERE CodFabricante = v_fab) THEN
        RAISE EXCEPTION 'El fabricante % no existe', v_fab;
    END IF;
    IF EXISTS (SELECT 1 FROM Materiales WHERE CodMateriales = v_cod) THEN
        RAISE EXCEPTION 'Ya existe un material con el código % (puede estar dado de baja)', v_cod;
    END IF;
    INSERT INTO Materiales (CodMateriales, CodRepuesto, CodFabricante, DescripcionMateriales)
    VALUES (v_cod, v_rep, v_fab, btrim(p_descripcion));
END $$;

CREATE OR REPLACE PROCEDURE sp_actualizar_material(p_cod VARCHAR, p_codrepuesto VARCHAR,
                                                   p_codfabricante VARCHAR, p_descripcion VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
    v_rep TEXT := upper(btrim(COALESCE(p_codrepuesto, '')));
    v_fab TEXT := upper(btrim(COALESCE(p_codfabricante, '')));
BEGIN
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción es obligatoria'; END IF;
    IF NOT EXISTS (SELECT 1 FROM Repuesto WHERE CodRepuesto = v_rep) THEN
        RAISE EXCEPTION 'El repuesto % no existe', v_rep;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Fabricante WHERE CodFabricante = v_fab) THEN
        RAISE EXCEPTION 'El fabricante % no existe', v_fab;
    END IF;
    UPDATE Materiales
       SET CodRepuesto = v_rep, CodFabricante = v_fab, DescripcionMateriales = btrim(p_descripcion)
     WHERE CodMateriales = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'El material % no existe o está dado de baja', v_cod; END IF;
END $$;

CREATE OR REPLACE PROCEDURE sp_eliminar_material(p_cod VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    UPDATE Materiales SET activo = FALSE WHERE CodMateriales = v_cod AND activo;
    IF NOT FOUND THEN RAISE EXCEPTION 'El material % no existe o ya está dado de baja', v_cod; END IF;
END $$;

-- PROCEDIMIENTOS: ÓRDENES DE TRABAJO

CREATE OR REPLACE PROCEDURE sp_crear_orden(p_cod VARCHAR, p_codencargado VARCHAR,
                                           p_descripcion VARCHAR, p_fecha DATE, p_estado VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_cod    TEXT := upper(btrim(COALESCE(p_cod, '')));
    v_enc    TEXT := upper(btrim(COALESCE(p_codencargado, '')));
    v_estado TEXT := upper(btrim(COALESCE(p_estado, '')));
BEGIN
    IF v_cod = '' THEN RAISE EXCEPTION 'El código de la orden es obligatorio'; END IF;
    IF COALESCE(btrim(p_descripcion), '') = '' THEN RAISE EXCEPTION 'La descripción de la orden es obligatoria'; END IF;
    IF p_fecha IS NULL THEN RAISE EXCEPTION 'La fecha de la orden es obligatoria'; END IF;
    IF v_estado NOT IN ('PENDIENTE', 'EN PROCESO', 'COMPLETADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'Estado de orden no válido: %', v_estado;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Encargado WHERE CodEncargado = v_enc) THEN
        RAISE EXCEPTION 'El encargado % no existe', v_enc;
    END IF;
    IF EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = v_cod) THEN
        RAISE EXCEPTION 'Ya existe la orden %', v_cod;
    END IF;
    INSERT INTO CabeceraOrdenTrabajo (CodDocumento, CodEncargado, DescripcionDocumento, Fecha, Estado)
    VALUES (v_cod, v_enc, btrim(p_descripcion), p_fecha, v_estado);
END $$;

CREATE OR REPLACE PROCEDURE sp_actualizar_estado_orden(p_cod VARCHAR, p_estado VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_cod    TEXT := upper(btrim(COALESCE(p_cod, '')));
    v_estado TEXT := upper(btrim(COALESCE(p_estado, '')));
BEGIN
    IF v_estado NOT IN ('PENDIENTE', 'EN PROCESO', 'COMPLETADA', 'CANCELADA') THEN
        RAISE EXCEPTION 'Estado de orden no válido: %', v_estado;
    END IF;
    UPDATE CabeceraOrdenTrabajo SET Estado = v_estado WHERE CodDocumento = v_cod;
    IF NOT FOUND THEN RAISE EXCEPTION 'La orden % no existe', v_cod; END IF;
END $$;

CREATE OR REPLACE PROCEDURE sp_agregar_det_persona(p_doc VARCHAR, p_cod VARCHAR, p_horas NUMERIC, p_cantidad INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_doc TEXT := upper(btrim(COALESCE(p_doc, '')));
    v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(p_horas, 0) <= 0 OR COALESCE(p_cantidad, 0) <= 0 THEN
        RAISE EXCEPTION 'Horas y cantidad de personas deben ser mayores a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = v_doc) THEN
        RAISE EXCEPTION 'La orden % no existe', v_doc;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Persona WHERE CodPersona = v_cod AND activo) THEN
        RAISE EXCEPTION 'La persona % no existe o está dada de baja', v_cod;
    END IF;
    IF EXISTS (SELECT 1 FROM DetallePersona WHERE CodDocumento = v_doc AND CodPersona = v_cod) THEN
        RAISE EXCEPTION 'La persona % ya está asignada a la orden %', v_cod, v_doc;
    END IF;
    INSERT INTO DetallePersona (CodDocumento, CodPersona, HorasPersona, CantidadPersonas)
    VALUES (v_doc, v_cod, p_horas, p_cantidad);
END $$;

CREATE OR REPLACE PROCEDURE sp_agregar_det_herramienta(p_doc VARCHAR, p_cod VARCHAR, p_horas NUMERIC, p_cantidad INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_doc TEXT := upper(btrim(COALESCE(p_doc, '')));
    v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(p_horas, 0) <= 0 OR COALESCE(p_cantidad, 0) <= 0 THEN
        RAISE EXCEPTION 'Horas y cantidad de herramientas deben ser mayores a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = v_doc) THEN
        RAISE EXCEPTION 'La orden % no existe', v_doc;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Herramientas WHERE CodHerramientas = v_cod AND activo) THEN
        RAISE EXCEPTION 'La herramienta % no existe o está dada de baja', v_cod;
    END IF;
    IF EXISTS (SELECT 1 FROM DetalleHerramientas WHERE CodDocumento = v_doc AND CodHerramientas = v_cod) THEN
        RAISE EXCEPTION 'La herramienta % ya está asignada a la orden %', v_cod, v_doc;
    END IF;
    INSERT INTO DetalleHerramientas (CodDocumento, CodHerramientas, CantidadHerramientas, HorasHerramientas)
    VALUES (v_doc, v_cod, p_cantidad, p_horas);
END $$;

CREATE OR REPLACE PROCEDURE sp_agregar_det_maquinaria(p_doc VARCHAR, p_cod VARCHAR, p_horas NUMERIC, p_cantidad INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_doc TEXT := upper(btrim(COALESCE(p_doc, '')));
    v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(p_horas, 0) <= 0 OR COALESCE(p_cantidad, 0) <= 0 THEN
        RAISE EXCEPTION 'Horas y cantidad de maquinaria deben ser mayores a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = v_doc) THEN
        RAISE EXCEPTION 'La orden % no existe', v_doc;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Maquinaria WHERE CodMaquinaria = v_cod AND activo) THEN
        RAISE EXCEPTION 'La maquinaria % no existe o está dada de baja', v_cod;
    END IF;
    IF EXISTS (SELECT 1 FROM DetalleMaquinaria WHERE CodDocumento = v_doc AND CodMaquinaria = v_cod) THEN
        RAISE EXCEPTION 'La maquinaria % ya está asignada a la orden %', v_cod, v_doc;
    END IF;
    INSERT INTO DetalleMaquinaria (CodDocumento, CodMaquinaria, HorasMaquinaria, CantidadMaquinaria)
    VALUES (v_doc, v_cod, p_horas, p_cantidad);
END $$;

CREATE OR REPLACE PROCEDURE sp_agregar_det_material(p_doc VARCHAR, p_cod VARCHAR, p_cantidad INTEGER)
LANGUAGE plpgsql AS $$
DECLARE
    v_doc TEXT := upper(btrim(COALESCE(p_doc, '')));
    v_cod TEXT := upper(btrim(COALESCE(p_cod, '')));
BEGIN
    IF COALESCE(p_cantidad, 0) <= 0 THEN
        RAISE EXCEPTION 'La cantidad de materiales debe ser mayor a cero';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = v_doc) THEN
        RAISE EXCEPTION 'La orden % no existe', v_doc;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Materiales WHERE CodMateriales = v_cod AND activo) THEN
        RAISE EXCEPTION 'El material % no existe o está dado de baja', v_cod;
    END IF;
    IF EXISTS (SELECT 1 FROM DetalleMateriales WHERE CodDocumento = v_doc AND CodMateriales = v_cod) THEN
        RAISE EXCEPTION 'El material % ya está asignado a la orden %', v_cod, v_doc;
    END IF;
    INSERT INTO DetalleMateriales (CodDocumento, CodMateriales, CantidadMateriales)
    VALUES (v_doc, v_cod, p_cantidad);
END $$;

-- FUNCIONES DEL INFORME IMPRIMIBLE

CREATE OR REPLACE FUNCTION fn_informe_cabecera(p_cod VARCHAR)
RETURNS TABLE(coddocumento TEXT, descripcion TEXT, encargado TEXT, fecha DATE, estado TEXT)
LANGUAGE sql STABLE AS $$
    SELECT c.CodDocumento::text, c.DescripcionDocumento::text, e.Nombre::text, c.Fecha, c.Estado::text
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    WHERE c.CodDocumento = btrim(p_cod);
$$;

CREATE OR REPLACE FUNCTION fn_informe_personas(p_cod VARCHAR)
RETURNS TABLE(cantidad INTEGER, horas_hombre NUMERIC, especialidad TEXT)
LANGUAGE sql STABLE AS $$
    SELECT dp.CantidadPersonas::integer, dp.HorasPersona::numeric, p.Especialidad::text
    FROM DetallePersona dp
    JOIN Persona p ON p.CodPersona = dp.CodPersona
    WHERE dp.CodDocumento = btrim(p_cod)
    ORDER BY p.Especialidad;
$$;

CREATE OR REPLACE FUNCTION fn_informe_materiales(p_cod VARCHAR)
RETURNS TABLE(cantidad INTEGER, descripcion TEXT, codrepuesto TEXT, codfabricante TEXT)
LANGUAGE sql STABLE AS $$
    SELECT dm.CantidadMateriales::integer, m.DescripcionMateriales::text,
           r.CodRepuesto::text, f.CodFabricante::text
    FROM DetalleMateriales dm
    JOIN Materiales m  ON m.CodMateriales  = dm.CodMateriales
    JOIN Repuesto   r  ON r.CodRepuesto    = m.CodRepuesto
    JOIN Fabricante f  ON f.CodFabricante  = m.CodFabricante
    WHERE dm.CodDocumento = btrim(p_cod)
    ORDER BY m.DescripcionMateriales;
$$;

CREATE OR REPLACE FUNCTION fn_informe_herramientas(p_cod VARCHAR)
RETURNS TABLE(cantidad INTEGER, horas NUMERIC, descripcion TEXT)
LANGUAGE sql STABLE AS $$
    SELECT dh.CantidadHerramientas::integer, dh.HorasHerramientas::numeric, h.DescripcionHerramientas::text
    FROM DetalleHerramientas dh
    JOIN Herramientas h ON h.CodHerramientas = dh.CodHerramientas
    WHERE dh.CodDocumento = btrim(p_cod)
    ORDER BY h.DescripcionHerramientas;
$$;

CREATE OR REPLACE FUNCTION fn_informe_maquinaria(p_cod VARCHAR)
RETURNS TABLE(cantidad INTEGER, horas NUMERIC, descripcion TEXT)
LANGUAGE sql STABLE AS $$
    SELECT dq.CantidadMaquinaria::integer, dq.HorasMaquinaria::numeric, m.DescripcionMaquinaria::text
    FROM DetalleMaquinaria dq
    JOIN Maquinaria m ON m.CodMaquinaria = dq.CodMaquinaria
    WHERE dq.CodDocumento = btrim(p_cod)
    ORDER BY m.DescripcionMaquinaria;
$$;

-- Órdenes por estado
CREATE OR REPLACE FUNCTION rpt_ordenes_por_estado(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(estado TEXT, total_ordenes BIGINT, encargados_distintos BIGINT,
              primera_fecha DATE, ultima_fecha DATE, porcentaje NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT c.Estado::text,
           COUNT(*)::bigint,
           COUNT(DISTINCT e.CodEncargado)::bigint,
           MIN(c.Fecha),
           MAX(c.Fecha),
           ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)::numeric
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY c.Estado
    ORDER BY COUNT(*) DESC, c.Estado;
$$;

-- Órdenes con totales de recursos asignados
CREATE OR REPLACE FUNCTION rpt_ordenes_detalladas(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(documento TEXT, descripcion TEXT, encargado TEXT, fecha DATE, estado TEXT,
              personas NUMERIC, materiales NUMERIC, herramientas NUMERIC, maquinas NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT c.CodDocumento::text, c.DescripcionDocumento::text, e.Nombre::text, c.Fecha, c.Estado::text,
           COALESCE(dp.n, 0)::numeric, COALESCE(dm.n, 0)::numeric,
           COALESCE(dh.n, 0)::numeric, COALESCE(dq.n, 0)::numeric
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    LEFT JOIN (SELECT CodDocumento, SUM(CantidadPersonas)     AS n FROM DetallePersona      GROUP BY CodDocumento) dp ON dp.CodDocumento = c.CodDocumento
    LEFT JOIN (SELECT CodDocumento, SUM(CantidadMateriales)   AS n FROM DetalleMateriales   GROUP BY CodDocumento) dm ON dm.CodDocumento = c.CodDocumento
    LEFT JOIN (SELECT CodDocumento, SUM(CantidadHerramientas) AS n FROM DetalleHerramientas GROUP BY CodDocumento) dh ON dh.CodDocumento = c.CodDocumento
    LEFT JOIN (SELECT CodDocumento, SUM(CantidadMaquinaria)   AS n FROM DetalleMaquinaria   GROUP BY CodDocumento) dq ON dq.CodDocumento = c.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    ORDER BY c.Fecha DESC, c.CodDocumento DESC;
$$;

-- Horas hombre por especialidad
CREATE OR REPLACE FUNCTION rpt_horas_hombre_por_especialidad(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(especialidad TEXT, ordenes BIGINT, personas_asignadas NUMERIC, horas_hombre NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT p.Especialidad::text,
           COUNT(DISTINCT c.CodDocumento)::bigint,
           SUM(dp.CantidadPersonas)::numeric,
           SUM(dp.HorasPersona)::numeric
    FROM DetallePersona dp
    JOIN Persona p                ON p.CodPersona   = dp.CodPersona
    JOIN CabeceraOrdenTrabajo c   ON c.CodDocumento = dp.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY p.Especialidad
    ORDER BY SUM(dp.HorasPersona) DESC, p.Especialidad;
$$;

-- Materiales más utilizados
CREATE OR REPLACE FUNCTION rpt_materiales_mas_usados(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(codigo TEXT, material TEXT, codigo_repuesto TEXT, codigo_fabricante TEXT,
              ordenes BIGINT, cantidad_total NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT m.CodMateriales::text, m.DescripcionMateriales::text, r.CodRepuesto::text, f.CodFabricante::text,
           COUNT(DISTINCT c.CodDocumento)::bigint,
           SUM(dm.CantidadMateriales)::numeric
    FROM DetalleMateriales dm
    JOIN Materiales m           ON m.CodMateriales = dm.CodMateriales
    JOIN Repuesto r             ON r.CodRepuesto   = m.CodRepuesto
    JOIN Fabricante f           ON f.CodFabricante = m.CodFabricante
    JOIN CabeceraOrdenTrabajo c ON c.CodDocumento  = dm.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY m.CodMateriales, m.DescripcionMateriales, r.CodRepuesto, f.CodFabricante
    ORDER BY SUM(dm.CantidadMateriales) DESC, m.CodMateriales
    LIMIT 10;
$$;

-- Maquinaria asignada por encargado
CREATE OR REPLACE FUNCTION rpt_maquinaria_por_encargado(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(encargado TEXT, codigo_maquinaria TEXT, maquinaria TEXT, ordenes BIGINT,
              unidades NUMERIC, horas_totales NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT e.Nombre::text, mq.CodMaquinaria::text, mq.DescripcionMaquinaria::text,
           COUNT(DISTINCT c.CodDocumento)::bigint,
           SUM(dq.CantidadMaquinaria)::numeric,
           SUM(dq.HorasMaquinaria)::numeric
    FROM DetalleMaquinaria dq
    JOIN Maquinaria mq          ON mq.CodMaquinaria = dq.CodMaquinaria
    JOIN CabeceraOrdenTrabajo c ON c.CodDocumento   = dq.CodDocumento
    JOIN Encargado e            ON e.CodEncargado   = c.CodEncargado
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY e.Nombre, mq.CodMaquinaria, mq.DescripcionMaquinaria
    ORDER BY e.Nombre, SUM(dq.HorasMaquinaria) DESC;
$$;

-- Herramientas más utilizadas 
CREATE OR REPLACE FUNCTION rpt_herramientas_mas_usadas(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(codigo TEXT, herramienta TEXT, ordenes BIGINT, unidades NUMERIC, horas_totales NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT h.CodHerramientas::text, h.DescripcionHerramientas::text,
           COUNT(DISTINCT c.CodDocumento)::bigint,
           SUM(dh.CantidadHerramientas)::numeric,
           SUM(dh.HorasHerramientas)::numeric
    FROM DetalleHerramientas dh
    JOIN Herramientas h         ON h.CodHerramientas = dh.CodHerramientas
    JOIN CabeceraOrdenTrabajo c ON c.CodDocumento    = dh.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY h.CodHerramientas, h.DescripcionHerramientas
    ORDER BY SUM(dh.HorasHerramientas) DESC, h.CodHerramientas
    LIMIT 10;
$$;

-- Órdenes por encargado, desglosadas por estado
CREATE OR REPLACE FUNCTION rpt_ordenes_por_encargado(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(encargado TEXT, total_ordenes BIGINT, pendientes BIGINT, en_proceso BIGINT,
              completadas BIGINT, canceladas BIGINT, ultima_orden DATE)
LANGUAGE sql STABLE AS $$
    SELECT e.Nombre::text,
           COUNT(*)::bigint,
           COUNT(*) FILTER (WHERE c.Estado = 'PENDIENTE')::bigint,
           COUNT(*) FILTER (WHERE c.Estado = 'EN PROCESO')::bigint,
           COUNT(*) FILTER (WHERE c.Estado = 'COMPLETADA')::bigint,
           COUNT(*) FILTER (WHERE c.Estado = 'CANCELADA')::bigint,
           MAX(c.Fecha)
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY e.CodEncargado, e.Nombre
    ORDER BY COUNT(*) DESC, e.Nombre;
$$;

-- Consumo de materiales por fabricante
CREATE OR REPLACE FUNCTION rpt_consumo_por_fabricante(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(fabricante TEXT, materiales_distintos BIGINT, ordenes BIGINT, cantidad_total NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT f.CodFabricante::text,
           COUNT(DISTINCT m.CodMateriales)::bigint,
           COUNT(DISTINCT c.CodDocumento)::bigint,
           SUM(dm.CantidadMateriales)::numeric
    FROM DetalleMateriales dm
    JOIN Materiales m           ON m.CodMateriales = dm.CodMateriales
    JOIN Fabricante f           ON f.CodFabricante = m.CodFabricante
    JOIN CabeceraOrdenTrabajo c ON c.CodDocumento  = dm.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY f.CodFabricante
    ORDER BY SUM(dm.CantidadMateriales) DESC, f.CodFabricante;
$$;

-- Órdenes y horas hombre por mes
CREATE OR REPLACE FUNCTION rpt_ordenes_por_mes(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(mes TEXT, ordenes BIGINT, encargados BIGINT, horas_hombre NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT to_char(c.Fecha, 'YYYY-MM')::text,
           COUNT(DISTINCT c.CodDocumento)::bigint,
           COUNT(DISTINCT e.CodEncargado)::bigint,
           COALESCE(SUM(dp.HorasPersona), 0)::numeric
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    LEFT JOIN DetallePersona dp ON dp.CodDocumento = c.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    GROUP BY to_char(c.Fecha, 'YYYY-MM')
    ORDER BY 1 DESC;
$$;

--Resumen de recursos por orden
CREATE OR REPLACE FUNCTION rpt_recursos_por_orden(p_desde DATE DEFAULT NULL, p_hasta DATE DEFAULT NULL, p_estado TEXT DEFAULT NULL)
RETURNS TABLE(documento TEXT, descripcion TEXT, estado TEXT, horas_hombre NUMERIC,
              horas_herramientas NUMERIC, horas_maquinaria NUMERIC, cantidad_materiales NUMERIC)
LANGUAGE sql STABLE AS $$
    SELECT c.CodDocumento::text, c.DescripcionDocumento::text, c.Estado::text,
           COALESCE(dp.h, 0)::numeric, COALESCE(dh.h, 0)::numeric,
           COALESCE(dq.h, 0)::numeric, COALESCE(dm.n, 0)::numeric
    FROM CabeceraOrdenTrabajo c
    JOIN Encargado e ON e.CodEncargado = c.CodEncargado
    LEFT JOIN (SELECT CodDocumento, SUM(HorasPersona)       AS h FROM DetallePersona      GROUP BY CodDocumento) dp ON dp.CodDocumento = c.CodDocumento
    LEFT JOIN (SELECT CodDocumento, SUM(HorasHerramientas)  AS h FROM DetalleHerramientas GROUP BY CodDocumento) dh ON dh.CodDocumento = c.CodDocumento
    LEFT JOIN (SELECT CodDocumento, SUM(HorasMaquinaria)    AS h FROM DetalleMaquinaria   GROUP BY CodDocumento) dq ON dq.CodDocumento = c.CodDocumento
    LEFT JOIN (SELECT CodDocumento, SUM(CantidadMateriales) AS n FROM DetalleMateriales   GROUP BY CodDocumento) dm ON dm.CodDocumento = c.CodDocumento
    WHERE (p_desde IS NULL OR c.Fecha >= p_desde)
      AND (p_hasta IS NULL OR c.Fecha <= p_hasta)
      AND (COALESCE(p_estado, '') = '' OR c.Estado = p_estado)
    ORDER BY COALESCE(dp.h, 0) DESC, c.CodDocumento;
$$;

-- Registros adicionales
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = 'DOC0000006') THEN
        CALL sp_crear_orden('DOC0000006', 'ENC001', 'MANTENIMIENTO PREVENTIVO CHANCADORA PRIMARIA', DATE '2026-08-10', 'COMPLETADA');
        CALL sp_agregar_det_persona('DOC0000006', 'PER004', 12.00, 2);
        CALL sp_agregar_det_material('DOC0000006', 'MAT003', 10);
        CALL sp_agregar_det_herramienta('DOC0000006', 'HER002', 8.00, 2);
        CALL sp_agregar_det_maquinaria('DOC0000006', 'MAQ004', 4.00, 1);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM CabeceraOrdenTrabajo WHERE CodDocumento = 'DOC0000007') THEN
        CALL sp_crear_orden('DOC0000007', 'ENC002', 'ALINEAMIENTO LÁSER DE MOTOR PRINCIPAL MOLINO SAG', DATE '2026-09-15', 'PENDIENTE');
        CALL sp_agregar_det_persona('DOC0000007', 'PER001', 6.00, 1);
        CALL sp_agregar_det_persona('DOC0000007', 'PER002', 6.00, 1);
        CALL sp_agregar_det_herramienta('DOC0000007', 'HER003', 6.00, 1);
    END IF;
END $$;
