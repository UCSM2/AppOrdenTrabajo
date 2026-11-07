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


#Registrar 

#Borrar

#Actualizar