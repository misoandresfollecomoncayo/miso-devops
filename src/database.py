from flask_sqlalchemy import SQLAlchemy
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

db = SQLAlchemy()

def create_database_if_not_exists(db_name='miso_devops_blacklists', db_user='postgres', db_password='postgres', db_host='localhost', db_port=5432):
    """
    Crea la base de datos PostgreSQL si no existe.
    """
    try:
        # Conectar a la base de datos 'postgres' por defecto
        conn = psycopg2.connect(
            host=db_host,
            port=db_port,
            user=db_user,
            password=db_password,
            database='postgres'
        )
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        cursor = conn.cursor()
        
        # Verificar si la base de datos existe
        cursor.execute(
            "SELECT 1 FROM pg_database WHERE datname = %s",
            (db_name,)
        )
        exists = cursor.fetchone()
        
        if not exists:
            # Crear la base de datos
            cursor.execute(f'CREATE DATABASE {db_name}')
            print(f"✓ Base de datos '{db_name}' creada exitosamente")
        else:
            print(f"✓ Base de datos '{db_name}' ya existe")
        
        cursor.close()
        conn.close()
        return True
        
    except psycopg2.Error as e:
        print(f"✗ Error al crear la base de datos: {e}")
        return False
