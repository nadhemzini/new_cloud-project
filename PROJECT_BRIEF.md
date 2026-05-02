# 🚀 Full-Stack Cloud Deployment Project Brief
> React + Spring Boot + PostgreSQL on AWS — with Terraform & CI/CD

---

## 📌 Overview

This document describes a **full-stack web application** intended for deployment on **AWS** using an **AWS Sandbox environment**. The goal is to validate the cloud architecture end-to-end before moving to production. All infrastructure is automated via **Terraform**, and deployments are handled through a **CI/CD pipeline** (GitHub Actions).

---

## 🧱 Project Architecture

```
┌─────────────────────────────────────────────┐
│                  AWS Cloud                  │
│                                             │
│  ┌──────────┐   ┌──────────┐  ┌──────────┐ │
│  │  React   │──▶│  Spring  │──▶│Postgres  │ │
│  │ Frontend │   │   Boot   │  │    DB    │ │
│  │  (S3 +   │   │  (ECS    │  │  (RDS)   │ │
│  │CloudFront│   │ Fargate) │  │          │ │
│  └──────────┘   └──────────┘  └──────────┘ │
└─────────────────────────────────────────────┘
```

| Layer      | Technology              | AWS Service         |
|------------|-------------------------|---------------------|
| Frontend   | React 18 + Vite         | S3 + CloudFront     |
| Backend    | Spring Boot 3 (Java 17) | ECS Fargate         |
| Database   | PostgreSQL 15           | RDS (Free Tier)     |
| IaC        | Terraform >= 1.6        | —                   |
| CI/CD      | GitHub Actions          | ECR + S3 + ECS      |

---

## 📁 Project Structure

```
project-root/
├── frontend/                  # React application
│   ├── src/
│   │   ├── components/
│   │   ├── pages/
│   │   ├── services/          # API calls to backend
│   │   └── main.jsx
│   ├── Dockerfile
│   ├── vite.config.js
│   └── package.json
│
├── backend/                   # Spring Boot application
│   ├── src/main/java/
│   │   └── com/app/
│   │       ├── controller/
│   │       ├── service/
│   │       ├── repository/
│   │       └── model/
│   ├── src/main/resources/
│   │   └── application.yml
│   ├── Dockerfile
│   └── pom.xml
│
├── terraform/                 # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── vpc.tf
│   ├── ecs.tf
│   ├── rds.tf
│   ├── s3_cloudfront.tf
│   ├── ecr.tf
│   └── iam.tf
│
├── .github/
│   └── workflows/
│       ├── deploy-frontend.yml
│       ├── deploy-backend.yml
│       └── terraform-apply.yml
│
├── docker-compose.yml         # Local development
└── README.md                  # Project documentation (see below)
```

---

## 🖥️ Frontend — React

### What it does
A minimal React SPA that:
- Displays a list of items fetched from the backend API
- Allows creating and deleting items (basic CRUD)
- Shows API health status

### Key Files

**`frontend/Dockerfile`**
```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

**`frontend/vite.config.js`** — configure `VITE_API_URL` via environment variable at build time.

**Deployment:** Built as static files → uploaded to **S3** → served via **CloudFront** (HTTPS).

---

## ⚙️ Backend — Spring Boot

### What it does
A REST API that:
- Exposes `GET /api/items`, `POST /api/items`, `DELETE /api/items/{id}`
- Connects to PostgreSQL via Spring Data JPA
- Has a `GET /actuator/health` endpoint (used by ECS health checks)

### Key Config

**`backend/src/main/resources/application.yml`**
```yaml
spring:
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: false

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health
```

**`backend/Dockerfile`**
```dockerfile
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Deployment:** Docker image → pushed to **ECR** → deployed on **ECS Fargate**.

---

## 🗄️ Database — PostgreSQL (RDS)

- Engine: PostgreSQL 15
- Instance: `db.t3.micro` (AWS Free Tier eligible)
- Storage: 20 GB gp2
- Access: Private subnet only (backend connects via VPC)
- Credentials: Stored in **AWS Secrets Manager**, injected as env vars into ECS task

---

## 🏗️ Terraform Infrastructure

### Prerequisites
```bash
terraform >= 1.6
AWS CLI configured with sandbox credentials
An S3 bucket for Terraform state (create manually once)
```

### Modules / Files

| File | Purpose |
|------|---------|
| `vpc.tf` | VPC, subnets (public/private), IGW, NAT, route tables |
| `ecr.tf` | ECR repository for backend Docker image |
| `ecs.tf` | ECS Cluster, Task Definition, Service, ALB |
| `rds.tf` | RDS PostgreSQL instance, subnet group, security group |
| `s3_cloudfront.tf` | S3 bucket (static hosting) + CloudFront distribution |
| `iam.tf` | ECS task execution role, S3/ECR permissions |
| `variables.tf` | Input variables (region, env name, DB password, etc.) |
| `outputs.tf` | CloudFront URL, ALB URL, RDS endpoint |

### Usage
```bash
cd terraform/

# Initialize (point to your S3 state bucket)
terraform init \
  -backend-config="bucket=YOUR_SANDBOX_STATE_BUCKET" \
  -backend-config="key=app/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Preview changes
terraform plan -var-file="sandbox.tfvars"

# Apply
terraform apply -var-file="sandbox.tfvars"

# Destroy (clean up sandbox)
terraform destroy -var-file="sandbox.tfvars"
```

### `sandbox.tfvars` (example — do NOT commit secrets)
```hcl
aws_region   = "us-east-1"
environment  = "sandbox"
db_password  = "REPLACE_WITH_STRONG_PASSWORD"
```

---

## 🔄 CI/CD — GitHub Actions

### Workflows

#### 1. `terraform-apply.yml` — Infrastructure provisioning
Trigger: push to `main` (changes in `terraform/`)
Steps: checkout → configure AWS credentials → terraform init → plan → apply

#### 2. `deploy-backend.yml` — Backend deployment
Trigger: push to `main` (changes in `backend/`)
Steps: checkout → build Docker image → push to ECR → update ECS service → wait for deployment

#### 3. `deploy-frontend.yml` — Frontend deployment
Trigger: push to `main` (changes in `frontend/`)
Steps: checkout → npm install → npm build → sync to S3 → CloudFront cache invalidation

### Required GitHub Secrets
```
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_ACCOUNT_ID
AWS_REGION
TF_STATE_BUCKET
DB_PASSWORD
```

---

## 🐳 Local Development

**`docker-compose.yml`** — spin up the full stack locally:
```yaml
version: "3.9"
services:
  db:
    image: postgres:15
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: localpass
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      DB_URL: jdbc:postgresql://db:5432/appdb
      DB_USERNAME: appuser
      DB_PASSWORD: localpass
    depends_on:
      - db

  frontend:
    build: ./frontend
    ports:
      - "3000:80"
    environment:
      VITE_API_URL: http://localhost:8080
    depends_on:
      - backend
```

```bash
# Start everything locally
docker-compose up --build

# Frontend: http://localhost:3000
# Backend:  http://localhost:8080
# DB:       localhost:5432
```

---

## ✅ Cloud Testing Checklist (Sandbox)

- [ ] Terraform apply completes without errors
- [ ] RDS instance is reachable from ECS tasks (not from public internet)
- [ ] Backend health check passes: `GET https://<ALB_URL>/actuator/health`
- [ ] Frontend loads via CloudFront URL
- [ ] Frontend successfully calls backend API (CORS configured)
- [ ] CRUD operations work end-to-end
- [ ] CI/CD pipeline triggers on push and deploys successfully
- [ ] Secrets are not hardcoded anywhere (use Secrets Manager / env vars)
- [ ] `terraform destroy` cleanly removes all resources

---

## 💰 AWS Sandbox Cost Estimate

| Service | Type | Est. Monthly |
|---------|------|-------------|
| ECS Fargate | 0.25 vCPU / 0.5 GB | ~$5–10 |
| RDS PostgreSQL | db.t3.micro | ~$15 (or free tier) |
| CloudFront | Low traffic | ~$0–1 |
| S3 | Static files | ~$0 |
| ALB | 1 load balancer | ~$16 |
| NAT Gateway | 1 AZ | ~$32 |
| **Total** | | **~$70–80/month** |

> ⚠️ Always run `terraform destroy` when done testing in the sandbox to avoid unexpected charges.

---

## 📄 README.md (to include inside the project)

The project repo should contain a `README.md` covering:

1. **Project Summary** — what the app does
2. **Tech Stack** — React, Spring Boot, PostgreSQL, Terraform, GitHub Actions
3. **Local Setup** — prerequisites, `docker-compose up` instructions
4. **Terraform Setup** — backend config, tfvars, how to deploy
5. **CI/CD** — how the pipelines work, required secrets
6. **Architecture Diagram** — simple ASCII or image
7. **API Endpoints** — table of routes
8. **Environment Variables** — what each service expects
9. **Teardown** — how to destroy cloud resources

---

## 📬 Deliverables Summary

| Deliverable | Description |
|-------------|-------------|
| `frontend/` | React app with Dockerfile |
| `backend/` | Spring Boot REST API with Dockerfile |
| `docker-compose.yml` | Local full-stack dev environment |
| `terraform/` | Complete IaC for AWS (VPC, ECS, RDS, S3, CF) |
| `.github/workflows/` | 3 GitHub Actions pipelines |
| `README.md` | Project documentation |

---

*Document prepared for Antigravity — AWS Sandbox deployment validation.*
