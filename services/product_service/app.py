from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(title="ProductService")


class Product(BaseModel):
    id: int
    name: str
    price: float


_products = [Product(id=1, name="Widget", price=9.99)]


@app.get("/health")
def health():
    logger.info("API: GET /health - Input: None")
    result = {"status": "ok"}
    logger.info(f"API: GET /health - Output: {result}")
    return result


@app.get("/products", response_model=List[Product])
def list_products():
    logger.info("API: GET /products - Input: None")
    result = _products
    logger.info(f"API: GET /products - Output: {[product.dict() for product in result]}")
    return result


@app.get("/products/{product_id}", response_model=Product)
def get_product(product_id: int):
    logger.info(f"API: GET /products/{product_id} - Input: product_id={product_id}")
    for p in _products:
        if p.id == product_id:
            logger.info(f"API: GET /products/{product_id} - Output: {p.dict()}")
            return p
    logger.error(f"API: GET /products/{product_id} - Error: Product not found")
    raise HTTPException(status_code=404, detail="Product not found")


@app.post("/products", response_model=Product, status_code=201)
def create_product(p: Product):
    logger.info(f"API: POST /products - Input: {p.dict()}")
    # naive uniqueness by id
    for existing in _products:
        if existing.id == p.id:
            logger.error(f"API: POST /products - Error: ID {p.id} already exists")
            raise HTTPException(status_code=400, detail="ID already exists")
    _products.append(p)
    logger.info(f"API: POST /products - Output: {p.dict()}")
    return p
