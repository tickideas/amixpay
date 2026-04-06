# AmixPay — Deployment Guide

## Local Development Setup

### Prerequisites
- Node.js 20+
- Docker Desktop
- Flutter SDK 3.41.4 (already downloaded at `../flutter_windows_3.41.4-stable/flutter/`)
- Android Studio / Xcode

---

### 1. Backend — Run with Docker (Recommended)

```bash
cd "APP BUILD 2026/velocash-api"

# Copy environment file
cp .env.example .env
# Edit .env with your Stripe/Plaid/Wise API keys

# Start all services (API + PostgreSQL + Redis)
docker-compose up --build -d

# Run database migrations and seed
docker exec amixpay-api sh scripts/init-db.sh

# Check logs
docker-compose logs -f api

# API is available at: http://localhost:3000
# Health check: curl http://localhost:3000/health
```

### 2. Backend — Run Without Docker

```bash
# Prerequisites: PostgreSQL 15 + Redis 7 running locally

cd "APP BUILD 2026/velocash-api"
cp .env.example .env  # Edit with your DB credentials

npm install
npx knex migrate:latest  # Run all 10 migrations
npx knex seed:run         # Seed test data

node src/server.js
# OR with auto-reload:
npm install -g nodemon
nodemon src/server.js
```

### 3. Flutter App

```bash
cd "APP BUILD 2026/AmixPAY"

# Get dependencies
flutter pub get

# Run on Android emulator (API points to localhost via 10.0.2.2)
flutter run --dart-define=API_URL=http://10.0.2.2:3000/v1

# Run on iOS simulator
flutter run --dart-define=API_URL=http://localhost:3000/v1

# Run on physical device (replace with your machine IP)
flutter run --dart-define=API_URL=http://192.168.1.x:3000/v1
```

**Test credentials (after seeding):**
- `alice@amixpay.dev` / `Password123!` — $5,000 USD wallet
- `bob@amixpay.dev` / `Password123!` — £3,500 GBP wallet
- `admin@amixpay.dev` / `Password123!` — Admin access

---

## AWS Production Deployment

### Architecture Overview
```
Internet → CloudFront → ALB → ECS Fargate (API) → RDS PostgreSQL + ElastiCache Redis
                                                  → S3 (documents)
                                                  → Secrets Manager (API keys)
```

### Step 1: Prerequisites

```bash
# Install AWS CLI
pip install awscli
aws configure  # Set your Access Key, Secret, Region (us-east-1)

# Install Docker (for building)
# Install EB CLI or use ECS deploy tools
```

### Step 2: Create ECR Repository

```bash
# Create ECR repo
aws ecr create-repository --repository-name amixpay-api --region us-east-1

# Authenticate Docker to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

# Build and push image
cd "APP BUILD 2026/velocash-api"
docker build -t amixpay-api .
docker tag amixpay-api:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/amixpay-api:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/amixpay-api:latest
```

### Step 3: Create RDS PostgreSQL

```bash
aws rds create-db-instance \
  --db-instance-identifier amixpay-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version "15.4" \
  --master-username postgres \
  --master-user-password "YourStrongPassword" \
  --db-name amixpay \
  --allocated-storage 20 \
  --storage-type gp3 \
  --no-multi-az \
  --publicly-accessible false \
  --vpc-security-group-ids sg-xxxxxxxx \
  --region us-east-1
```

### Step 4: Create ElastiCache Redis

```bash
aws elasticache create-replication-group \
  --replication-group-id amixpay-redis \
  --description "AmixPay Redis Cache" \
  --num-cache-clusters 1 \
  --cache-node-type cache.t3.micro \
  --engine redis \
  --engine-version "7.0" \
  --region us-east-1
```

### Step 5: Store Secrets in AWS Secrets Manager

```bash
aws secretsmanager create-secret \
  --name amixpay/production \
  --secret-string '{
    "JWT_SECRET": "your-64-char-secret",
    "STRIPE_SECRET_KEY": "sk_live_...",
    "STRIPE_WEBHOOK_SECRET": "whsec_...",
    "WISE_API_KEY": "your-wise-key",
    "PLAID_SECRET": "your-plaid-secret",
    "PLAID_CLIENT_ID": "your-plaid-client-id",
    "OPEN_EXCHANGE_RATES_KEY": "your-oxr-key",
    "FIREBASE_SERVER_KEY": "your-fcm-key"
  }'
```

### Step 6: Create ECS Cluster + Task Definition

```bash
# Create ECS cluster
aws ecs create-cluster --cluster-name amixpay-cluster --region us-east-1

# Create task definition (save as task-def.json):
cat > task-def.json << 'EOF'
{
  "family": "amixpay-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::<ACCOUNT_ID>:role/ecsTaskExecutionRole",
  "containerDefinitions": [{
    "name": "api",
    "image": "<ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/amixpay-api:latest",
    "portMappings": [{"containerPort": 3000, "protocol": "tcp"}],
    "environment": [
      {"name": "NODE_ENV", "value": "production"},
      {"name": "PORT", "value": "3000"},
      {"name": "DB_HOST", "value": "<RDS_ENDPOINT>"},
      {"name": "DB_PORT", "value": "5432"},
      {"name": "DB_NAME", "value": "amixpay"},
      {"name": "DB_USER", "value": "postgres"},
      {"name": "REDIS_URL", "value": "redis://<ELASTICACHE_ENDPOINT>:6379"}
    ],
    "secrets": [
      {"name": "DB_PASSWORD", "valueFrom": "arn:aws:secretsmanager:...:amixpay/production:DB_PASSWORD::"},
      {"name": "JWT_SECRET", "valueFrom": "arn:aws:secretsmanager:...:amixpay/production:JWT_SECRET::"},
      {"name": "STRIPE_SECRET_KEY", "valueFrom": "arn:aws:secretsmanager:...:amixpay/production:STRIPE_SECRET_KEY::"}
    ],
    "healthCheck": {
      "command": ["CMD-SHELL", "wget -qO- http://localhost:3000/health || exit 1"],
      "interval": 30, "timeout": 5, "retries": 3, "startPeriod": 30
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/amixpay-api",
        "awslogs-region": "us-east-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }]
}
EOF

aws ecs register-task-definition --cli-input-json file://task-def.json
```

### Step 7: Create Application Load Balancer

```bash
# Create ALB
aws elbv2 create-load-balancer \
  --name amixpay-alb \
  --subnets subnet-xxx subnet-yyy \
  --security-groups sg-xxx \
  --scheme internet-facing \
  --type application

# Create target group
aws elbv2 create-target-group \
  --name amixpay-tg \
  --protocol HTTP \
  --port 3000 \
  --vpc-id vpc-xxx \
  --target-type ip \
  --health-check-path /health

# Create listener (HTTPS requires ACM certificate)
aws elbv2 create-listener \
  --load-balancer-arn <ALB_ARN> \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=<TG_ARN>
```

### Step 8: Create ECS Service

```bash
aws ecs create-service \
  --cluster amixpay-cluster \
  --service-name amixpay-api \
  --task-definition amixpay-api:1 \
  --desired-count 2 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx,subnet-yyy],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=<TG_ARN>,containerName=api,containerPort=3000"
```

### Step 9: Run DB Migrations on Production

```bash
# Get a task to run migration
aws ecs run-task \
  --cluster amixpay-cluster \
  --task-definition amixpay-api:1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}" \
  --overrides '{"containerOverrides":[{"name":"api","command":["sh","scripts/init-db.sh"]}]}'
```

### Step 10: CloudFront CDN

```bash
aws cloudfront create-distribution \
  --origin-domain-name <ALB_DNS_NAME> \
  --default-root-object "" \
  # → Full distribution config in AWS console for HTTPS + custom domain
```

---

## GitHub Actions CI/CD Pipeline

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy AmixPay API

on:
  push:
    branches: [main]
    paths: ['velocash-api/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          cd velocash-api
          docker build -t $ECR_REGISTRY/amixpay-api:$IMAGE_TAG .
          docker push $ECR_REGISTRY/amixpay-api:$IMAGE_TAG
          echo "image=$ECR_REGISTRY/amixpay-api:$IMAGE_TAG" >> $GITHUB_OUTPUT

      - name: Update ECS Service
        run: |
          aws ecs update-service \
            --cluster amixpay-cluster \
            --service amixpay-api \
            --force-new-deployment
```

---

## S3 for KYC Documents

```bash
# Create private S3 bucket
aws s3 mb s3://amixpay-documents --region us-east-1

# Block all public access
aws s3api put-public-access-block \
  --bucket amixpay-documents \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Add bucket policy for ECS task role access only
```

---

## Flutter Production Build

```bash
cd "APP BUILD 2026/AmixPAY"

# Android APK (release)
flutter build apk --release \
  --dart-define=API_URL=https://api.amixpay.com/v1

# Android App Bundle (for Play Store)
flutter build appbundle --release \
  --dart-define=API_URL=https://api.amixpay.com/v1

# iOS (requires Mac + Xcode)
flutter build ios --release \
  --dart-define=API_URL=https://api.amixpay.com/v1
```

---

## Monitoring

| Service | Purpose | URL |
|---|---|---|
| CloudWatch Logs | Application logs | AWS Console → CloudWatch → /ecs/amixpay-api |
| CloudWatch Metrics | CPU, Memory, Request count | AWS Console → CloudWatch → Metrics |
| AWS X-Ray | Distributed tracing | Add `aws-xray-sdk` to backend |
| CloudTrail | API audit logs | AWS Console → CloudTrail |
| GuardDuty | Threat detection | Enable in AWS Console |

---

## Cost Estimate (MVP)

| Service | Instance | Monthly Cost |
|---|---|---|
| ECS Fargate | 2 tasks × 0.5 vCPU / 1GB | ~$30 |
| RDS PostgreSQL | db.t3.micro, 20GB | ~$15 |
| ElastiCache Redis | cache.t3.micro | ~$13 |
| ALB | 1 ALB | ~$16 |
| CloudFront | 1TB transfer | ~$85 |
| ECR | 1 image | ~$1 |
| **Total** | | **~$160/month** |
