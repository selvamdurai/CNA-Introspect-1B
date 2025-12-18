from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI(title="OrderService")


class Order(BaseModel):
    id: int
    product_id: int
    quantity: int


_orders = [Order(id=1, product_id=1, quantity=2)]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/orders", response_model=List[Order])
def list_orders():
    return _orders


@app.post("/orders", response_model=Order, status_code=201)
def create_order(o: Order):
    for existing in _orders:
        if existing.id == o.id:
            raise HTTPException(status_code=400, detail="ID already exists")
    _orders.append(o)
    return o
