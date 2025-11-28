import newrelic.agent

# Inicializar New Relic antes que nada
newrelic.agent.initialize()

from flask import Flask
from database import db
from os import getenv
from routes import blacklists_bp

DB_USER = getenv("DB_USER", "postgres")
DB_PASSWORD = getenv("DB_PASSWORD", "postgres")
DB_NAME = getenv("DB_NAME", "postdb")
DB_HOST = getenv("DB_HOST", "localhost")
DB_PORT = getenv("DB_PORT", "5432")

def create_app(testing=False):
    app = Flask(__name__)

    if testing:
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    else:
        # Solo importar y ejecutar create_database si no estamos en modo testing
        from database import create_database_if_not_exists
        create_database_if_not_exists(DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT)
        app.config['SQLALCHEMY_DATABASE_URI'] = (
            f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        )

    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    db.init_app(app)

    if not testing:
        with app.app_context():
            db.create_all()

    app.register_blueprint(blacklists_bp)

    return app

# Configuración para ejecución directa y como módulo
# Solo crear la app si NO estamos en modo testing
if getenv('TESTING') != 'true':
    app = create_app(testing=False)
else:
    app = None

if __name__ == '__main__':
    if app is None:
        app = create_app(testing=False)
    app.run(debug=True, host='0.0.0.0', port=5000)