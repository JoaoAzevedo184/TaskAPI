from fastapi.testclient import TestClient
from app.main import app
import os

client = TestClient(app)

def setup_module(module):
    # remove DB to start fresh
    try:
        os.remove("tasks.db")
    except FileNotFoundError:
        pass

def test_create_and_get_task():
    res = client.post("/tasks", json={"title":"Teste", "description":"desc", "done": False})
    assert res.status_code == 201
    body = res.json()
    assert body["title"] == "Teste"
    task_id = body["id"]

    get_res = client.get(f"/tasks/{task_id}")
    assert get_res.status_code == 200
    assert get_res.json()["title"] == "Teste"