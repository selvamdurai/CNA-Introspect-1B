#!/usr/bin/env bash
set -euo pipefail

echo "Creating Python virtualenv and installing requirements"
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
pip install -r requirements.txt
pip install -r services/product_service/requirements.txt
pip install -r services/order_service/requirements.txt

echo "Dev environment ready. Activate with: source .venv/bin/activate"
