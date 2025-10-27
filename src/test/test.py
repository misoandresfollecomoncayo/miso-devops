import sys, os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import json
import pytest
from unittest.mock import patch
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