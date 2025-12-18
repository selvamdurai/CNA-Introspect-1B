# CNA-Introspect-1B Microservices

This workspace contains two minimal Python microservices:

- ProductService (FastAPI)
- OrderService (FastAPI)

Each service has a small API, tests, and a Dockerfile. There's a top-level `buildspec.yml` suitable for AWS CodeBuild that runs tests.

Quick local steps:

1. Create a virtualenv and install dependencies for a service:
   python -m venv .venv
   source .venv/bin/activate
   pip install -r services/product_service/requirements.txt

2. Run the app (example):
   uvicorn services.product_service.app:app --reload --port 8001

3. Run tests:
   pytest -q

AWS steps (these are automated in this workflow):
- Create CodeCommit repository `CNA-Introspect-1B` using AWS CLI with profile `selvam`.
- Push the code and create a CodeBuild project that uses the repo and `buildspec.yml`.
