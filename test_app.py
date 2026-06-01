import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'app'))

import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home(client):
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'running'
    assert 'message' in data

def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    data = response.get_json()
    assert data['status'] == 'healthy'

def test_add(client):
    response = client.get('/add/3/7')
    assert response.status_code == 200
    data = response.get_json()
    assert data['result'] == 10

def test_add_negatives(client):
    response = client.get('/add/-5/5')
    assert response.status_code == 200
    data = response.get_json()
    assert data['result'] == 0
