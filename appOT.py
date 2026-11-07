import psycopg2

#Conección DB
def conectarBD():
    return psycopg2.connect(
        host="localhost",
        database="OrdenTrabajoDB",
        user="postgres",
        password="root",
        port="5432"
    )

#Menu
def menuOT():
    print("\n SISTEMA ORDEN TRABAJO")
    print("")
    print("\n 1. Registrar Orden de Trabajo")
    print("2. Modificar Orden Trabajo")
    print("3. Eliminar Orden Trabajo")
    print("4. Revisar información")
    print("5. Finalizar")
    print("")
    return input("Opciones [1 - 5]")

#Registrar 
def insertOT():
    print("REGISTRAR ORDEN TRABAJO")
    codigo=input("Codigo Documento: ")
    encargado=input ()
    descripcion=input ()
    fecha= input ()
    estado=input ()
    conn=conectar
    cur.execute("CALL sp_insertar_orden(%s, %s, %s, %s, %s)", (cod, encargado, desc, fecha, estado))

#Borrar

#Actualizar