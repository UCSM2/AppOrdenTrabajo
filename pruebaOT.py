import tkinter as tk
from tkinter import ttk, messagebox
import psycopg2
from datetime import datetime

# =====================================================================
# CONEXIÓN NATIVA A LA BASE DE DATOS
# =====================================================================
def conectar_bd():
    try:
        # !!! RECUERDA COLOCAR AQUÍ TUS CREDENCIALES REALES DE PGADMIN4 !!!
        conn = psycopg2.connect(
            host="localhost",
            database="OrdenTrabajoDB",
            user="postgres",
            password="root",
            port="5432"
        )
        # Forzar al conector a interpretar la comunicación en UTF-8
        conn.set_client_encoding('UTF8')
        return conn
    except Exception as e:
        # Intentar decodificar el mensaje de error de Windows/PostgreSQL de forma segura
        try:
            error_msg = str(e).encode('utf-8', errors='replace').decode('utf-8')
        except:
            error_msg = str(e)
        messagebox.showerror("Error de Conexión", f"No se pudo conectar a PostgreSQL:\n{error_msg}")
        return None

# =====================================================================
# CLASE PRINCIPAL DE LA APLICACIÓN
# =====================================================================
class SistemaOrdenesTrabajo(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("SISTEMA CENTRALIZADO DE ÓRDENES DE TRABAJO - ENTORNO CORPORATIVO")
        self.geometry("900x700")
        
        # Configuración de estilos formales (Colores ejecutivos e institucionales)
        self.style = ttk.Style()
        self.style.theme_use("clam")
        self.style.configure(".", font=("Helvetica", 10))
        self.style.configure("TNotebook.Tab", font=("Helvetica", 10, "bold"), padding=[10, 5])
        self.style.configure("Header.TLabel", font=("Helvetica", 14, "bold"), foreground="#1A365D")
        self.style.configure("DocHeader.TLabel", font=("Courier New", 14, "bold"), foreground="#000000")
        self.style.configure("Formal.TButton", font=("Helvetica", 10, "bold"), background="#1A365D", foreground="white")
        self.style.map("Formal.TButton", background=[("active", "#2A4365")])

        # Crear control de pestañas
        self.notebook = ttk.Notebook(self)
        self.notebook.pack(expand=True, fill="both", padx=10, pady=10)

        # Inicialización de las Pestañas Independientes
        self.tab_orden = ttk.Frame(self.notebook)
        self.tab_personas = ttk.Frame(self.notebook)
        self.tab_materiales = ttk.Frame(self.notebook)
        self.tab_herramientas = ttk.Frame(self.notebook)

        self.notebook.add(self.tab_orden, text="📄 Generar Orden de Trabajo")
        self.notebook.add(self.tab_personas, text="👥 Catálogo Personas")
        self.notebook.add(self.tab_materiales, text="📦 Catálogo Materiales")
        self.notebook.add(self.tab_herramientas, text="🛠️ Catálogo Herramientas")

        # Construir interfaces de pestañas
        self.construir_tab_personas()
        self.construir_tab_materiales()
        self.construir_tab_herramientas()
        self.construir_tab_orden_trabajo()

    # =====================================================================
    # PANTALLAS DE INSERCIÓN INDEPENDIENTES (CATÁLOGOS)
    # =====================================================================
    def construir_tab_personas(self):
        frame = ttk.LabelFrame(self.tab_personas, text=" Registro de Nuevo Personal Técnico ", padding=20)
        frame.pack(padx=20, pady=20, fill="x")

        ttk.Label(frame, text="Código de Persona (Máx 6 caract.):").grid(row=0, column=0, sticky="w", pady=5)
        entry_cod = ttk.Entry(frame, width=15)
        entry_cod.grid(row=0, column=1, sticky="w", pady=5)

        ttk.Label(frame, text="Especialidad Técnica (Ejem: Mecánico):").grid(row=1, column=0, sticky="w", pady=5)
        entry_esp = ttk.Entry(frame, width=40)
        entry_esp.grid(row=1, column=1, sticky="w", pady=5)

        def guardar():
            cod, esp = entry_cod.get().strip().upper(), entry_esp.get().strip()
            if not cod or not esp:
                return messagebox.showwarning("Campos Incompletos", "Por favor llene todos los campos.")
            if len(cod) > 6:
                return messagebox.showwarning("Exceso de caracteres", "El código debe ser de máximo 6 caracteres.")
            
            conn = conectar_bd()
            if conn:
                try:
                    cur = conn.cursor()
                    cur.execute("INSERT INTO Persona (CodPersona, Especialidad) VALUES (%s, %s);", (cod[:6], esp))
                    conn.commit()
                    messagebox.showinfo("Éxito", f"Personal técnico {cod} guardado en base de datos.")
                    entry_cod.delete(0, tk.END)
                    entry_esp.delete(0, tk.END)
                    self.cargar_comboboxes()
                except Exception as e:
                    messagebox.showerror("Error SQL", f"No se pudo guardar:\n{e}")
                finally:
                    conn.close()

        ttk.Button(frame, text="Guardar Personal", style="Formal.TButton", command=guardar).grid(row=2, column=1, sticky="e", pady=15)

    def construir_tab_materiales(self):
        # Contenedor principal con scroll o espaciado
        frame_main = ttk.Frame(self.tab_materiales, padding=10)
        frame_main.pack(fill="both", expand=True)

        # SECCIÓN 1: Registrar Fabricante y Repuesto Primero (Para evitar errores de FK)
        frame_aux = ttk.LabelFrame(frame_main, text=" 1. Registro Temprano de Atributos Base (Opcional) ", padding=10)
        frame_aux.pack(fill="x", pady=5)

        ttk.Label(frame_aux, text="Cod Fabricante:").grid(row=0, column=0, sticky="w", padx=5, pady=2)
        ent_fab_new = ttk.Entry(frame_aux, width=10)
        ent_fab_new.grid(row=0, column=1, sticky="w", padx=5, pady=2)

        def guardar_fab():
            val = ent_fab_new.get().strip().upper()
            if not val: return messagebox.showwarning("Atención", "Ingrese código")
            conn = conectar_bd()
            if conn:
                try:
                    cur = conn.cursor()
                    cur.execute("INSERT INTO Fabricante (CodFabricante) VALUES (%s);", (val,))
                    conn.commit()
                    messagebox.showinfo("Éxito", f"Fabricante {val} registrado.")
                    ent_fab_new.delete(0, tk.END)
                    self.cargar_comboboxes()
                except Exception as e: messagebox.showerror("Error SQL", e)
                finally: conn.close()

        ttk.Button(frame_aux, text="Reg. Fabricante", command=guardar_fab).grid(row=0, column=2, padx=10)

        ttk.Label(frame_aux, text="Cod Repuesto:").grid(row=0, column=3, sticky="w", padx=5, pady=2)
        ent_rep_new = ttk.Entry(frame_aux, width=10)
        ent_rep_new.grid(row=0, column=4, sticky="w", padx=5, pady=2)

        def guardar_rep():
            val = ent_rep_new.get().strip().upper()
            if not val: return messagebox.showwarning("Atención", "Ingrese código")
            conn = conectar_bd()
            if conn:
                try:
                    cur = conn.cursor()
                    cur.execute("INSERT INTO Repuesto (CodRepuesto) VALUES (%s);", (val,))
                    conn.commit()
                    messagebox.showinfo("Éxito", f"Repuesto {val} registrado.")
                    ent_rep_new.delete(0, tk.END)
                    self.cargar_comboboxes()
                except Exception as e: messagebox.showerror("Error SQL", e)
                finally: conn.close()

        ttk.Button(frame_aux, text="Reg. Repuesto", command=guardar_rep).grid(row=0, column=5, padx=10)

        # SECCIÓN 2: Registro del Material Maestro
        frame_mat = ttk.LabelFrame(frame_main, text=" 2. Registro del Material Comercial ", padding=15)
        frame_mat.pack(fill="x", pady=10)

        ttk.Label(frame_mat, text="Código Material (CHAR 6):").grid(row=0, column=0, sticky="w", pady=5)
        entry_cod = ttk.Entry(frame_mat, width=15)
        entry_cod.grid(row=0, column=1, sticky="w", pady=5)

        ttk.Label(frame_mat, text="Descripción Material:").grid(row=1, column=0, sticky="w", pady=5)
        entry_desc = ttk.Entry(frame_mat, width=40)
        entry_desc.grid(row=1, column=1, columnspan=3, sticky="w", pady=5)

        # Desplegables dinámicos vinculados a Fabricante y Repuesto
        ttk.Label(frame_mat, text="Asociar Repuesto FK:").grid(row=2, column=0, sticky="w", pady=5)
        self.cb_rep_mat = ttk.Combobox(frame_mat, width=20, state="readonly")
        self.cb_rep_mat.grid(row=2, column=1, sticky="w", pady=5)

        ttk.Label(frame_mat, text="Asociar Fabricante FK:").grid(row=2, column=2, sticky="w", pady=5)
        self.cb_fab_mat = ttk.Combobox(frame_mat, width=20, state="readonly")
        self.cb_fab_mat.grid(row=2, column=3, sticky="w", pady=5)

        def guardar_material_maestro():
            cod = entry_cod.get().strip().upper()
            desc = entry_desc.get().strip()
            rep = self.cb_rep_mat.get().strip()
            fab = self.cb_fab_mat.get().strip()

            if not cod or not desc or not rep or not fab:
                return messagebox.showwarning("Campos Vacíos", "Todos los campos del bloque maestro son mandatorios.")
            
            if len(cod) > 6:
                return messagebox.showwarning("Tamaño Excedido", "El Código de Material no debe superar los 6 caracteres (CHAR 6).")

            conn = conectar_bd()
            if conn:
                try:
                    cur = conn.cursor()
                    cur.execute("""
                        INSERT INTO Materiales (CodMateriales, CodRepuesto, CodFabricante, DescripcionMateriales) 
                        VALUES (%s, %s, %s, %s);
                    """, (cod[:6], rep[:6], fab[:6], desc))
                    conn.commit()
                    messagebox.showinfo("Transacción Completa", f"Material '{cod}' añadido exitosamente al almacén.")
                    entry_cod.delete(0, tk.END)
                    entry_desc.delete(0, tk.END)
                except Exception as e:
                    messagebox.showerror("Fallo de Consistencia", f"Error de Inserción:\n{e}")
                finally:
                    conn.close()

        ttk.Button(frame_mat, text="Guardar Registro Material", style="Formal.TButton", command=guardar_material_maestro).grid(row=3, column=3, sticky="e", pady=15)

    def construir_tab_herramientas(self):
        frame = ttk.LabelFrame(self.tab_herramientas, text=" Registro de Nueva Herramienta ", padding=20)
        frame.pack(padx=20, pady=20, fill="x")

        ttk.Label(frame, text="Código Herramienta (CHAR 6):").grid(row=0, column=0, sticky="w", pady=5)
        entry_cod = ttk.Entry(frame, width=15)
        entry_cod.grid(row=0, column=1, sticky="w", pady=5)

        ttk.Label(frame, text="Descripción de Caja/Equipo:").grid(row=1, column=0, sticky="w", pady=5)
        entry_desc = ttk.Entry(frame, width=40)
        entry_desc.grid(row=1, column=1, sticky="w", pady=5)

        def guardar():
            cod, desc = entry_cod.get().strip().upper(), entry_desc.get().strip()
            if not cod or not desc: 
                return messagebox.showwarning("Campos Incompletos", "Llene todos los campos.")
            if len(cod) > 6:
                return messagebox.showwarning("Exceso de caracteres", "El código debe ser de máximo 6 caracteres.")
                
            conn = conectar_bd()
            if conn:
                try:
                    cur = conn.cursor()
                    cur.execute("INSERT INTO Herramientas (CodHerramientas, DescripcionHerramientas) VALUES (%s, %s);", (cod[:6], desc))
                    conn.commit()
                    messagebox.showinfo("Éxito", f"Herramienta {cod} registrada correctamente.")
                    entry_cod.delete(0, tk.END)
                    entry_desc.delete(0, tk.END)
                    self.cargar_comboboxes()
                except Exception as e: messagebox.showerror("Error SQL", e)
                finally: conn.close()

        ttk.Button(frame, text="Guardar Herramienta", style="Formal.TButton", command=guardar).grid(row=2, column=1, sticky="e", pady=15)

    # =====================================================================
    # PANTALLA PRINCIPAL: GENERACIÓN Y VISTA DE IMPRESIÓN OFICIAL
    # =====================================================================
    def construir_tab_orden_trabajo(self):
        # Frame izquierdo: Formulario de Selección
        frame_form = ttk.LabelFrame(self.tab_orden, text=" Datos de la Orden de Trabajo ", padding=15)
        frame_form.pack(side="left", fill="both", expand=True, padx=10, pady=10)

        ttk.Label(frame_form, text="N° Documento:").grid(row=0, column=0, sticky="w", pady=5)
        self.ent_doc = ttk.Entry(frame_form, width=15)
        self.ent_doc.insert(0, "DOC0000006")
        self.ent_doc.grid(row=0, column=1, sticky="w", pady=5)

        ttk.Label(frame_form, text="Descripción General:").grid(row=1, column=0, sticky="w", pady=5)
        self.ent_desc = ttk.Entry(frame_form, width=30)
        self.ent_desc.grid(row=1, column=1, columnspan=2, sticky="w", pady=5)

        # Selectores Dinámicos conectados a la BD
        ttk.Label(frame_form, text="Asignar Personal:").grid(row=2, column=0, sticky="w", pady=5)
        self.cb_persona = ttk.Combobox(frame_form, postcommand=self.cargar_comboboxes, width=27, state="readonly")
        self.cb_persona.grid(row=2, column=1, sticky="w", pady=5)

        ttk.Label(frame_form, text="Asignar Herramienta:").grid(row=3, column=0, sticky="w", pady=5)
        self.cb_herramienta = ttk.Combobox(frame_form, width=27, state="readonly")
        self.cb_herramienta.grid(row=3, column=1, sticky="w", pady=5)

        # Botón para estructurar e imprimir el formato formal
        btn_imprimir = ttk.Button(frame_form, text="Visualizar Orden Oficial", style="Formal.TButton", command=self.generar_vista_oficial)
        btn_imprimir.grid(row=5, column=0, columnspan=3, pady=25, sticky="ew")

        # Frame derecho: Contenedor del Documento Formal (Estilo papel oficial)
        self.frame_documento = ttk.LabelFrame(self.tab_orden, text=" Vista de Impresión del Documento ")
        self.frame_documento.pack(side="right", fill="both", expand=True, padx=10, pady=10)

        # Área de texto enriquecido simulando papel bond
        self.txt_papel = tk.Text(self.frame_documento, bg="#FFFFFF", fg="#000000", font=("Courier New", 10), wrap="none", bd=2, relief="solid")
        self.txt_papel.pack(expand=True, fill="both", padx=10, pady=10)
        
        self.cargar_comboboxes()

    def cargar_comboboxes(self):
        """ Consulta de manera nativa los catálogos para alimentar los formularios """
        conn = conectar_bd()
        if conn:
            try:
                cur = conn.cursor()
                # 1. Cargar Personas (Filtra solo códigos limpios)
                cur.execute("SELECT CodPersona FROM Persona;")
                self.cb_persona['values'] = [r[0].strip() for r in cur.fetchall()]
                
                # 2. Cargar Herramientas
                cur.execute("SELECT CodHerramientas FROM Herramientas;")
                self.cb_herramienta['values'] = [r[0].strip() for r in cur.fetchall()]
                
                # 3. Cargar Repuestos (Para la pestaña de materiales)
                cur.execute("SELECT CodRepuesto FROM Repuesto;")
                list_rep = [r[0].strip() for r in cur.fetchall()]
                if hasattr(self, 'cb_rep_mat'): self.cb_rep_mat['values'] = list_rep
                
                # 4. Cargar Fabricantes (Para la pestaña de materiales)
                cur.execute("SELECT CodFabricante FROM Fabricante;")
                list_fab = [r[0].strip() for r in cur.fetchall()]
                if hasattr(self, 'cb_fab_mat'): self.cb_fab_mat['values'] = list_fab
                
            except Exception as e: 
                print(f"Error al poblar controles: {e}")
            finally: 
                conn.close()

        # =====================================================================
    # MAQUETACIÓN DEL DOCUMENTO OFICIAL FORMAL (VISTA DE IMPRESIÓN)
    # =====================================================================
    def generar_vista_oficial(self):
        doc_num = self.ent_doc.get().upper()
        descripcion = self.ent_desc.get()
        persona_sel = self.cb_persona.get()
        herramienta_sel = self.cb_herramienta.get()
        fecha_hoy = datetime.now().strftime("%Y-%m-%d %H:%M")
        
        if not doc_num or not descripcion:
            return messagebox.showwarning("Atención", "Debe ingresar el N° de Documento y la Descripción.")

        # Diseño del esqueleto del Documento Formal usando caracteres limpios
        documento_texto = f"""
===========================================================================
                      COMPAÑÍA DE OPERACIONES MINERAS S.A.
                            SISTEMA DE GESTIÓN MANT.
===========================================================================
DOCUMENTO OFICIAL: ÓRDEN DE TRABAJO             EMISIÓN: {fecha_hoy}
CÓDIGO DE CONTROL: {doc_num}                     ESTADO: EMITIDO
---------------------------------------------------------------------------

1. ESPECIFICACIONES GENERALES DE LA OPERACIÓN
---------------------------------------------------------------------------
DESCRIPCIÓN DEL COMPONENTE:
>> {descripcion.upper()}

2. ASIGNACIÓN DE PERSONAL TÉCNICO CALIFICADO
---------------------------------------------------------------------------
CÓDIGO EMPLEADO   | ESPECIALIDAD ASIGNADA
---------------------------------------------------------------------------
{persona_sel if persona_sel else "S/A - SIN ASIGNAR"}

3. RECURSOS LOGÍSTICOS Y CAJAS DE HERRAMIENTAS
---------------------------------------------------------------------------
CÓDIGO DE KIT     | DESCRIPCIÓN DEL EQUIPO DE APOYO
---------------------------------------------------------------------------
{herramienta_sel if herramienta_sel else "S/A - SIN ASIGNAR"}

4. CONSUMO DE MATERIALES (ORDEN GENERAL)
---------------------------------------------------------------------------
CÓDIGO MATERIAL   | CANTIDAD REQUERIDA     | UNIDAD DE MEDIDA
---------------------------------------------------------------------------
MAT001            | 1.00                   | EA (Unidades)
MAT002            | 0.25                   | L  (Litros)
MAT003            | 5.00                   | L  (Litros)
MAT004            | 152.00                 | EA (Unidades)
MAT005            | 152.00                 | EA (Unidades)
---------------------------------------------------------------------------

---------------------------                         ---------------------------
     FIRMA RESPONSABLE                                   SUPERVISOR DE GUARDIA
     ÁREA MANTENIMIENTO                                    PLANTEA OPERATIVA

===========================================================================
             DOCUMENTO CONFIDENCIAL - PARA USO INTERNO DE LA EMPRESA
===========================================================================
"""
        # Dibujar en la pantalla simuladora de impresión
        self.txt_papel.delete("1.0", tk.END)
        self.txt_papel.insert(tk.END, documento_texto)
        messagebox.showinfo("Impresión Generada", "La Orden de Trabajo se ha maquetado con formato oficial formal de forma correcta.")

if __name__ == "__main__":
    app = SistemaOrdenesTrabajo()
    app.mainloop()
