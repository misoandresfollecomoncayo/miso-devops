import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import json
import pytest
from unittest.mock import patch, MagicMock
from app import create_app

@pytest.fixture
def client():
    app = create_app(testing=True)
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_blacklists_success_with_mock(client):
    with patch('routes.db.session.add') as mock_add, \
         patch('routes.db.session.commit') as mock_commit:
        
        payload = {
            "email": "user@example.com",
            "app_uuid": "123e4567-e89b-12d3-a456-426614174000",
            "blocked_reason": "spam"
        }
        headers = {"Authorization": "Bearer token_valido"}

        response = client.post('/blacklists', json=payload, headers=headers)

        assert response.status_code == 200
        assert response.json["status"] == "success"

        mock_add.assert_called_once()
        mock_commit.assert_called_once()


# Tests para GET /blacklists/<email>

def test_get_blacklist_no_authorization_header(client):
    """Test cuando no se envía el header de autorización"""
    response = client.get('/blacklists/user@example.com')
    
    assert response.status_code == 401
    assert response.json["error"] == "No hay token de autorización"


def test_get_blacklist_invalid_bearer_format(client):
    """Test cuando el header de autorización no tiene formato Bearer"""
    headers = {"Authorization": "InvalidFormat token_valido"}
    response = client.get('/blacklists/user@example.com', headers=headers)
    
    assert response.status_code == 401
    assert response.json["error"] == "No hay token de autorización"


def test_get_blacklist_invalid_token(client):
    """Test cuando el token es inválido"""
    headers = {"Authorization": "Bearer token_invalido"}
    response = client.get('/blacklists/user@example.com', headers=headers)
    
    assert response.status_code == 403
    assert response.json["error"] == "Token inválido"


@patch('routes.is_email')
def test_get_blacklist_invalid_email_format(mock_is_email, client):
    """Test cuando el formato del email es inválido"""
    mock_is_email.return_value = False
    headers = {"Authorization": "Bearer token_valido"}
    
    response = client.get('/blacklists/invalid-email', headers=headers)
    
    assert response.status_code == 400
    assert response.json["error"] == "El parámetro email no es válido"
    mock_is_email.assert_called_once_with('invalid-email')


@patch('routes.Blacklists')
@patch('routes.is_email')
def test_get_blacklist_email_not_found(mock_is_email, mock_blacklists, client):
    """Test cuando el email no está en la lista negra"""
    mock_is_email.return_value = True
    mock_blacklists.query.filter_by.return_value.first.return_value = None
    
    headers = {"Authorization": "Bearer token_valido"}
    response = client.get('/blacklists/user@example.com', headers=headers)
    
    assert response.status_code == 200
    assert response.json["blacklist"] == False
    mock_is_email.assert_called_once_with('user@example.com')
    mock_blacklists.query.filter_by.assert_called_once_with(email='user@example.com')


@patch('routes.Blacklists')
@patch('routes.is_email')
def test_get_blacklist_email_found(mock_is_email, mock_blacklists, client):
    """Test cuando el email está en la lista negra"""
    mock_is_email.return_value = True
    
    # Mock del objeto blacklist encontrado
    mock_blacklist_obj = MagicMock()
    mock_blacklists.query.filter_by.return_value.first.return_value = mock_blacklist_obj
    
    headers = {"Authorization": "Bearer token_valido"}
    response = client.get('/blacklists/blocked@example.com', headers=headers)
    
    assert response.status_code == 200
    assert response.json["blacklist"] == True
    mock_is_email.assert_called_once_with('blocked@example.com')
    mock_blacklists.query.filter_by.assert_called_once_with(email='blocked@example.com')


