import psycopg2
import os
import configparser
RUTA= os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),"config", "config.ini")

def conectrar_db():
    conexion=psycopg2.connect(
        host=localhost
        database= OrdenTrabajoDB
        user=postgres
        password= root
        port=5432
    )
