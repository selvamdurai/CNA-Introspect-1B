#!/bin/bash

echo "=== Testing Dapr Communication Between Services ==="

# Get service endpoints
PRODUCT_SERVICE=$(kubectl get svc product-service -o jsonpath='{.spec.clusterIP}')
ORDER_SERVICE=$(kubectl get svc order-service -o jsonpath='{.spec.clusterIP}')

echo "Product Service IP: $PRODUCT_SERVICE"
echo "Order Service IP: $ORDER_SERVICE"

# Test 1: Check service health
echo ""
echo "1. Testing service health..."
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl -s http://$PRODUCT_SERVICE:8001/health
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- curl -s http://$ORDER_SERVICE:8002/health

# Test 2: Publish message via ProductService
echo ""
echo "2. Publishing order message via ProductService..."
kubectl run test-pod --image=curlimages/curl --rm -it --restart=Never -- \
  curl -X POST http://$PRODUCT_SERVICE:8001/publish-order \
  -H "Content-Type: application/json" \
  -d '{"order_id": 123, "product_id": 1, "quantity": 5, "customer": "test-user"}'

echo ""
echo "3. Check OrderService logs for received message:"
echo "kubectl logs -l app=order-service -c order-service --tail=10"

echo ""
echo "4. View Dapr logs:"
echo "kubectl logs -l app=product-service -c daprd --tail=5"
echo "kubectl logs -l app=order-service -c daprd --tail=5"