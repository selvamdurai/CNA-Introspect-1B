from fastapi.testclient import TestClient
from services.order_service.app import app


client = TestClient(app)


def test_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json() == {"status": "ok"}


def test_list_orders():
    r = client.get("/orders")
    assert r.status_code == 200
    assert isinstance(r.json(), list)
