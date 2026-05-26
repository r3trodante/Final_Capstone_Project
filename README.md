# Multi-Server DevOps CI/CD Pipeline & Automated Infrastructure

A production-grade, distributed DevOps pipeline demonstrating Continuous Integration, Automated Security Analysis, Containerization, and Continuous Deployment across an AWS EC2 multi-server architecture.

## 🏗️ Architecture Overview

The infrastructure is decoupled across dedicated AWS EC2 instances inside a shared VPC to isolate workloads and maximize performance:


| Server Component | Instance Type | Key Tools Installed | Connection Strategy |
| :--- | :--- | :--- | :--- |
| **Jenkins Master** | `c7i-flex.large` | Jenkins Core | Managed Web UI |
| **Jenkins Build Agent (`node1`)** | `c7i-flex.large` | Docker Engine, Git | Private IP / SSH |
| **SonarQube Server** | `c7i-flex.large` | SonarQube, Nginx Proxy | Private IP / Port 80 |
| **Deployment Server** | `t3.micro` | Docker Engine | Private IP / SSH Agent |

---

## 🚀 CI/CD Pipeline Workflow

The automation workflow is defined natively inside a declarative `Jenkinsfile` and follows these execution stages:

1. **Webhook Trigger**: A GitHub Webhook detects changes on the `main` branch and automatically kicks off the pipeline loop.
2. **Code Checkout**: The Jenkins Build Agent (`node1`) pulls the latest source code from GitHub.
3. **SonarQube Analysis**: Code quality, test inclusions, and static code security analyses are processed on the agent and securely pushed to the SonarQube dashboard via an internal Nginx reverse proxy.
4. **Docker Multi-Stage Build**: The pipeline executes an optimized multi-stage `Dockerfile` to create a lightweight, minimal Nginx production image.
5. **Registry Push**: The image is uniquely tagged with the Jenkins build number (`:BUILD_NUMBER`) and `:latest`, and securely uploaded to Docker Hub.
6. **Continuous Deployment (CD)**: Jenkins uses `sshagent` to securely tunnel into the Deployment Server over the AWS private network, pulls the fresh image, clean-replaces the old container, and updates the live site with zero downtime.

---

## 🔧 Local Setup & Configurations

### Prerequisites
* Ensure all EC2 security groups allow internal traffic over **Private IPs**.
* The **SonarQube** server must have port `9000` proxied through **Nginx on Port 80**.
* The **Jenkins Build Agent** user (`ubuntu`) must belong to the local system `docker` group.

### Required Jenkins Credentials
The pipeline relies on the following global credentials configured in the Jenkins Master Dashboard:
* `sonar_key` (Secret text): SonarQube analysis authentication token.
* `dockerhub_creds` (Username with password): Docker Hub account registry keys.
* `deployment_server_ssh` (SSH Username with private key): AWS `.pem` security key for the deployment server.

---

## 📈 Monitoring & Backups (Next Phase)
Future pipeline iterations will introduce comprehensive cluster health observability:
* **Prometheus & Grafana**: Setting up a centralized monitoring server scraping telemetry data from `node_exporter` endpoints on all 4 instances.
* **Log Rotation**: Custom log management rules and automated backup scripts via scheduled cron jobs.
