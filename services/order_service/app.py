from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(title="OrderService")


class Order(BaseModel):
    id: int
    product_id: int
    quantity: int


_orders = [Order(id=1, product_id=1, quantity=2)]


@app.get("/health")
def health():
    logger.info("API: GET /health - Input: None")
    result = {"status": "ok"}
    logger.info(f"API: GET /health - Output: {result}")
    return result


@app.get("/orders", response_model=List[Order])
def list_orders():
    logger.info("API: GET /orders - Input: None")
    result = _orders
    logger.info(f"API: GET /orders - Output: {[order.dict() for order in result]}")
    return result


@app.post("/orders", response_model=Order, status_code=201)
def create_order(o: Order):
    logger.info(f"API: POST /orders - Input: {o.dict()}")
    for existing in _orders:
        if existing.id == o.id:
            logger.error(f"API: POST /orders - Error: ID {o.id} already exists")
            raise HTTPException(status_code=400, detail="ID already exists")
    _orders.append(o)
    logger.info(f"API: POST /orders - Output: {o.dict()}")
    return o
