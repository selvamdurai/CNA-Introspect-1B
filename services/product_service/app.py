from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI(title="ProductService")


class Product(BaseModel):
    id: int
    name: str
    price: float


_products = [Product(id=1, name="Widget", price=9.99)]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/products", response_model=List[Product])
def list_products():
    return _products


@app.get("/products/{product_id}", response_model=Product)
def get_product(product_id: int):
    for p in _products:
        if p.id == product_id:
            return p
    raise HTTPException(status_code=404, detail="Product not found")


@app.post("/products", response_model=Product, status_code=201)
def create_product(p: Product):
    # naive uniqueness by id
    for existing in _products:
        if existing.id == p.id:
            raise HTTPException(status_code=400, detail="ID already exists")
    _products.append(p)
    return p
