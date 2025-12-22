# AWS Architecture Overview

This project runs two FastAPI microservices on Amazon EKS with Dapr pub/sub and AWS-native integrations. The diagram below captures the major components and data flow.

![Architecture Diagram](./aws-architecture.mmd)

> Tip: GitHub renders Mermaid diagrams automatically. If viewing elsewhere, paste the contents of `docs/aws-architecture.mmd` into a Mermaid live editor (e.g., https://mermaid.live) to visualize it.

## Key Components

- **Amazon EKS (`cna-introspect-eks`)** – Hosts the `product-service` publisher and `order-service` subscriber along with the Dapr control plane in `dapr-system`.
- **Dapr Sidecars** – Enable pub/sub and service invocation between the microservices and AWS SNS/SQS via the Dapr SDK.
- **AWS SNS + SQS** – `orders-topic` fan-outs to `orders-queue`, which the order service consumes, using IRSA (`dapr-pubsub-sa`).
- **Amazon ECR** – Stores the container images that the deployments pull.
- **Amazon CloudWatch** – Collects application/sidecar logs through the `cloudwatch-agent` + `fluent-bit` DaemonSets with IRSA access.

For more operational details (deployment order, scripts, health checks), see `docs/README-DEPLOYMENT.md` and the root `README.md`.
