# Enterprise Shop — DevOps Assignment

You are given a **working Java microservices application**. Your job is to build the
**DevOps around it yourself** — containerize it, orchestrate it, automate its delivery,
and run it on Kubernetes. The application code is done; **you will not change it** (except
config). Everything in "Your tasks" below is for you to create from scratch.

---

## The application (what you're given)

A small e-commerce platform: 6 Spring Boot services behind an API gateway, using
PostgreSQL, Redis and Kafka.

| Service | Port | Responsibility |
|---|---|---|
| api-gateway | 8080 | Single entry point, routing |
| user-service | 8081 | Register / login, issues JWTs |
| product-service | 8082 | Catalog + stock |
| order-service | 8083 | Order lifecycle, orchestration |
| payment-service | 8084 | Payment (simulated) |
| notification-service | 8085 | Email/SMS log (simulated) |

**How it talks:** the browser hits only the gateway. Placing an order writes to Postgres and
publishes an `order.placed` event to Kafka; product and payment services consume it; payment
success publishes `payment.completed`, which order and notification services react to. Redis
is used for caching and idempotency.

Each service owns **its own database** (no shared tables). Config is read from environment
variables (DB host, Redis host, Kafka bootstrap) — see each service's `application.yml`.

---

## Part 0 — Run it locally (do this first)

**Prerequisites:** JDK 21, Maven (or use your IDE's bundled one), Docker Desktop.

1. Start the data stores (provided for you):
   ```bash
   docker compose -f docker-compose.infra.yml up -d
   ```
   This runs Postgres (with the 5 databases created), Redis and Kafka only.

2. Build everything:
   ```bash
   mvn clean package -DskipTests
   ```

3. Run each service from your IDE (or `java -jar`), or just the ones you need. Defaults already
   point at `localhost` for Postgres/Redis/Kafka.

4. **Verify end-to-end** (gateway on 8080):
   ```bash
   # register a user
   curl -X POST localhost:8081/api/auth/register \
     -H 'Content-Type: application/json' \
     -d '{"email":"a@b.com","password":"password1","displayName":"A"}'

   # list products
   curl localhost:8082/api/products

   # place an order (use a real product id from above)
   curl -X POST localhost:8083/api/orders \
     -H 'Content-Type: application/json' -H 'Idempotency-Key: k1' \
     -d '{"userId":"<id>","lines":[{"productId":"p-1001","quantity":1,"unitPrice":89.99}]}'

   # a notification should appear
   curl localhost:8085/api/notifications
   ```

Done when: you can register, list products, place an order, and see the order become
`PAID` and a notification appear — and you can explain in the logs where Postgres, Redis and
Kafka each got used.

---

## Your tasks (build these yourself)

Do them in order — each builds on the last. For each, there's a **goal**, **requirements**, and
**acceptance criteria**. No solutions are given; that's the point.

### Task 1 — Containerize (Docker)
**Goal:** a Docker image for every service.
- Write a **multi-stage Dockerfile** per service: one stage builds the jar, a slim stage runs it.
- Run as a non-root user. Keep images small (JRE base, not JDK).
- Tag images with a version, not just `latest`.

Done when: `docker build` produces an image per service and `docker run` starts it against
the local data stores.

### Task 2 — Local orchestration (Docker Compose)
**Goal:** bring the **whole system** up with one command.
- Extend the provided infra compose into a full `docker-compose.yml` that also builds and runs
  all 6 services + the frontend, wired to Postgres/Redis/Kafka.
- Use `depends_on` + healthchecks so services wait for their dependencies.

Done when: `docker compose up --build` starts everything and the Part 0 verification passes
through the gateway on `:8080`.

### Task 3 — Kubernetes
**Goal:** run the system on a local cluster (minikube or kind).
- Write manifests: Deployment + Service per microservice; ConfigMap for non-secret config;
  Secret for DB password and JWT key.
- Add **liveness/readiness probes** (the services expose `/actuator/health/liveness` and
  `/readiness`). Set resource requests/limits.
- Run the data stores in-cluster too (or point at the host).

Done when: `kubectl get pods` shows everything Running and you can reach the gateway via a
Service/port-forward.

### Task 4 — Helm
**Goal:** replace raw manifests with a chart.
- Create a chart that templates the repetitive per-service YAML (image, port, env, replicas, probes).
- Support **per-environment values** (e.g. `values-dev.yaml`, `values-prod.yaml`) — different
  replica counts and image tags.

Done when: `helm install` deploys the whole app, and `helm upgrade -f values-prod.yaml`
changes the config without editing templates.

### Task 5 — CI/CD (Jenkins)
**Goal:** a pipeline that builds, tests, and deploys on a commit.
- Stages: checkout → build & unit test → build images → push to a registry → deploy (Helm).
- Fail the build if tests fail. Tag images with the Git commit SHA.

Done when: a push triggers the pipeline and a green run ends with the new version deployed.

### Task 6 — AWS (stretch)
**Goal:** run it on real cloud infra.
- Use **Terraform** to provision an EKS cluster + ECR repositories.
- Push images to ECR, deploy the Helm chart to EKS.
- Clean up with `terraform destroy` when done (cloud costs money).

Done when: the app runs on EKS and you can reach it, then tears down cleanly.

---

## What to submit / show
- Your Dockerfiles, compose file, k8s manifests, Helm chart, and Jenkinsfile (in your own repo).
- A short note: how an order flows through the system, and where each DevOps tool fits.
- A demo: one command (or pipeline run) that brings the system up, and the end-to-end order test passing.

## Rules
- Don't modify the Java source (config/env only).
- Prefer official base images; keep secrets out of Git.
- If you get stuck, read the service's `application.yml` to see exactly which env vars it needs.
