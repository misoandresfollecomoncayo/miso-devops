from datetime import datetime
import re
import uuid
from flask import request, jsonify
from app import create_app
from database import db
from models.blacklists import Blacklists

app = create_app()

def is_uuid(value: str) -> bool:
    try:
        obj = uuid.UUID(value)
        return str(obj) == value.lower()
    except:
        return False
    
def is_email(value: str) -> bool:
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, value) is not None

# Permite agregar un email a la lista negra global de la organización
@app.route('/blacklists', methods=['POST'])
def blacklists():
    # Validar header de autorización
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "No hay token de autorización"}), 401

    # Validar token válido
    token = auth_header.split(" ")[1]
    if token != "token_valido":
        return jsonify({"error": "Token inválido"}), 403

    # Validar contenido JSON
    if not request.is_json:
        return jsonify({"error": "El cuerpo de la solicitud debe ser JSON"}), 400

    data = request.get_json()
    email = data.get('email')
    app_uuid = data.get('app_uuid')
    blocked_reason = data.get('blocked_reason')

    # Validar parámetros obligatorios
    if not all([email, app_uuid]):
        return jsonify({"error": "Faltan parámetros requeridos"}), 400

    # Validar formato email
    if is_email(email) == False:
        return jsonify({"error": "El parámetro email no es válido"}), 400

    # Validar formato app_uuid
    if is_uuid(app_uuid) == False:
        return jsonify({"error": "El parámetro app_uuid no es válido"}), 400

    # Bloquear email
    bl = Blacklists(
        email=email,
        app_uuid=app_uuid,
        blocked_reason=blocked_reason,
        ip_address=request.remote_addr,
        created_timestamp=datetime.now()
    )
    db.session.add(bl)
    db.session.commit()
    
    # Respuesta
    return jsonify({
        "message": f"El email fue agregado correctamente",
        "status": "success"
    }), 200

@app.route('/blacklists/<email>', methods=['GET'])
def get_blacklist(email):
    # Validar header de autorización
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return jsonify({"error": "No hay token de autorización"}), 401

    # Validar token válido
    token = auth_header.split(" ")[1]
    if token != "token_valido":
        return jsonify({"error": "Token inválido"}), 403

    # Validar formato email
    if is_email(email) == False:
        return jsonify({"error": "El parámetro email no es válido"}), 400

    # Buscar email en la lista negra
    bl = Blacklists.query.filter_by(email=email).first()
    if not bl:
        return jsonify({
            "blacklist": False
        }), 200

    # Respuesta
    return jsonify({
        "blacklist": True
    }), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)