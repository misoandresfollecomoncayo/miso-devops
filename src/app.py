from flask import Flask
from database import db, create_database_if_not_exists

def create_app():
    # Crear la base de datos si no existe (ANTES de inicializar SQLAlchemy)
    create_database_if_not_exists()
    
    app = Flask(__name__)
    app.config['SQLALCHEMY_DATABASE_URI'] = 'postgresql+psycopg2://postgres:postgres@localhost:5432/miso_devops_blacklists'
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)

    with app.app_context():
        db.create_all()

    return app