# ☁️ Cloud Stack — Full-Stack AWS Deployment

> React + Spring Boot + PostgreSQL on AWS — automated with Terraform & GitHub Actions CI/CD

---

## 📌 Project Summary

A full-stack CRUD web application designed for cloud deployment on AWS. The frontend is a React SPA served via CloudFront, the backend is a Spring Boot REST API running on ECS Fargate, and the database is PostgreSQL on RDS. All infrastructure is provisioned with Terraform, and deployments are handled through GitHub Actions.

---

## 🧱 Tech Stack

| Layer      | Technology              | AWS Service         |
|------------|-------------------------|---------------------|
| Frontend   | React 18 + Vite 5       | S3 + CloudFront     |
| Backend    | Spring Boot 3 (Java 17) | ECS Fargate + ALB   |
| Database   | PostgreSQL 15           | RDS (db.t3.micro)   |
| IaC        | Terraform >= 1.6        | —                   |
| CI/CD      | GitHub Actions          | ECR + S3 + ECS      |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────┐
│                    AWS Cloud                    │
│                                                 │
│  ┌────────────┐   ┌────────────┐  ┌──────────┐ │
│  │   React    │──▶│  Spring    │──▶│ Postgres │ │
│  │  Frontend  │   │   Boot     │  │   DB     │ │
│  │ (S3 + CF)  │   │(ECS + ALB) │  │  (RDS)   │ │
│  └────────────┘   └────────────┘  └──────────┘ │
│                                                 │
│  CloudFront proxies /api/* to ALB               │
│  RDS in private subnets, ECS in private subnets │
└─────────────────────────────────────────────────┘
```

---

## 🚀 Local Development Setup

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & Docker Compose
- [Node.js 20+](https://nodejs.org/) (for frontend dev)
- [Java 17](https://adoptium.net/) + [Maven 3.9+](https://maven.apache.org/) (for backend dev)

### Quick Start (Docker Compose)

```bash
# Clone the project
git clone <your-repo-url>
cd project-root

# Start all services
docker-compose up --build

# Frontend:  http://localhost:3000
# Backend:   http://localhost:8080
# Database:  localhost:5432
```

### Frontend Dev (standalone)

```bash
cd frontend
npm install
npm run dev
# Runs at http://localhost:5173 with API proxy to :8080
```

### Backend Dev (standalone)

```bash
cd backend
mvn spring-boot:run
# Runs at http://localhost:8080
# Requires PostgreSQL running on localhost:5432
```

---

## 🌐 API Endpoints

| Method   | Path               | Description              |
|----------|--------------------|--------------------------|
| `GET`    | `/api/items`       | List all items           |
| `GET`    | `/api/items/{id}`  | Get item by ID           |
| `POST`   | `/api/items`       | Create a new item        |
| `PUT`    | `/api/items/{id}`  | Update an existing item  |
| `DELETE` | `/api/items/{id}`  | Delete an item           |
| `GET`    | `/actuator/health` | Health check (ECS)       |

### Request/Response Example

```bash
# Create an item
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "My Item", "description": "A test item"}'

# List all items
curl http://localhost:8080/api/items
```

---

## 🏗️ Terraform — AWS Infrastructure

### Prerequisites

```bash
terraform >= 1.6
aws cli configured with sandbox credentials
An S3 bucket for Terraform state (create manually once)
```

### Deploy

```bash
cd terraform/

# Initialize (point to your S3 state bucket)
terraform init \
  -backend-config="bucket=YOUR_STATE_BUCKET" \
  -backend-config="key=app/terraform.tfstate" \
  -backend-config="region=us-east-1"

# Preview
terraform plan -var="db_password=YOUR_STRONG_PASSWORD"

# Apply
terraform apply -var="db_password=YOUR_STRONG_PASSWORD"
```

### Using a tfvars file

Create `terraform/sandbox.tfvars`:
```hcl
aws_region   = "us-east-1"
environment  = "sandbox"
db_password  = "REPLACE_WITH_STRONG_PASSWORD"
```

Then run:
```bash
terraform plan -var-file="sandbox.tfvars"
terraform apply -var-file="sandbox.tfvars"
```

### Teardown

```bash
terraform destroy -var-file="sandbox.tfvars"
```

> ⚠️ Always run `terraform destroy` when done testing to avoid unexpected charges.

---

## 🔄 CI/CD — GitHub Actions

### Workflows

| Workflow | Trigger | What it does |
|----------|---------|-------------|
| `terraform-apply.yml` | Push to `main` (changes in `terraform/`) | Init → Validate → Plan → Apply |
| `deploy-backend.yml` | Push to `main` (changes in `backend/`) | Build Docker → Push ECR → Redeploy ECS |
| `deploy-frontend.yml` | Push to `main` (changes in `frontend/`) | Build React → Sync S3 → Invalidate CloudFront |

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | IAM access key |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_ACCOUNT_ID` | Your AWS account ID |
| `AWS_REGION` | e.g. `us-east-1` |
| `TF_STATE_BUCKET` | S3 bucket name for Terraform state |
| `DB_PASSWORD` | PostgreSQL master password |

---

## 🔐 Environment Variables

### Backend

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_URL` | JDBC connection string | `jdbc:postgresql://localhost:5432/appdb` |
| `DB_USERNAME` | Database username | `appuser` |
| `DB_PASSWORD` | Database password | `localpass` |
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | `http://localhost:3000,http://localhost:5173` |

### Frontend

| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_API_URL` | Backend API base URL | `""` (same origin) |

---

## 💰 AWS Cost Estimate (Sandbox)

| Service | Type | Est. Monthly |
|---------|------|-------------|
| ECS Fargate | 0.25 vCPU / 0.5 GB | ~$5–10 |
| RDS PostgreSQL | db.t3.micro | ~$15 (or free tier) |
| CloudFront | Low traffic | ~$0–1 |
| S3 | Static files | ~$0 |
| ALB | 1 load balancer | ~$16 |
| NAT Gateway | 1 AZ | ~$32 |
| **Total** | | **~$70–80/month** |

---

## 📁 Project Structure

```
project-root/
├── frontend/                  # React SPA (Vite)
│   ├── src/
│   │   ├── components/        # ItemList, ItemForm
│   │   ├── services/          # API client
│   │   ├── App.jsx            # Main application
│   │   ├── App.css            # Styles
│   │   └── main.jsx           # Entry point
│   ├── Dockerfile
│   ├── nginx.conf
│   └── package.json
│
├── backend/                   # Spring Boot REST API
│   ├── src/main/java/com/app/
│   │   ├── controller/        # REST endpoints
│   │   ├── service/           # Business logic
│   │   ├── repository/        # Data access
│   │   ├── model/             # JPA entities
│   │   └── config/            # CORS config
│   ├── Dockerfile
│   └── pom.xml
│
├── terraform/                 # AWS Infrastructure as Code
│   ├── main.tf                # Provider & backend
│   ├── vpc.tf                 # VPC, subnets, NAT
│   ├── ecs.tf                 # ECS Cluster, ALB, Service
│   ├── rds.tf                 # PostgreSQL RDS
│   ├── s3_cloudfront.tf       # S3 + CloudFront
│   ├── ecr.tf                 # ECR repository
│   ├── iam.tf                 # IAM roles
│   ├── variables.tf           # Input variables
│   └── outputs.tf             # Output values
│
├── .github/workflows/         # CI/CD pipelines
│   ├── terraform-apply.yml
│   ├── deploy-backend.yml
│   └── deploy-frontend.yml
│
├── docker-compose.yml         # Local dev environment
└── README.md
```

---

## ✅ Testing Checklist

- [ ] `docker-compose up --build` starts all services
- [ ] Backend health: `GET http://localhost:8080/actuator/health → {"status":"UP"}`
- [ ] Frontend loads at `http://localhost:3000`
- [ ] CRUD operations work end-to-end
- [ ] Terraform apply completes without errors
- [ ] RDS reachable from ECS only (not public)
- [ ] CloudFront serves frontend and proxies `/api/*`
- [ ] CI/CD pipelines trigger on push to `main`
- [ ] No hardcoded secrets anywhere
- [ ] `terraform destroy` cleanly removes all resources
