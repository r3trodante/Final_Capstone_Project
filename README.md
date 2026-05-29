# Multi-Server DevOps CI/CD Pipeline & Automated Infrastructure

A production-grade, distributed DevOps pipeline demonstrating Continuous Integration, Automated Security Analysis, Containerization, Continuous Deployment, Automated Smoke Testing, ChatOps, and Cloud Backups across an AWS EC2 multi-server architecture.

## 🏗️ Architecture Overview
The infrastructure is decoupled across dedicated AWS EC2 instances inside a shared VPC to eliminate resource starvation, isolate blast radiuses, and maximize system performance:


| Server Component | Instance Type | Key Tools Installed | Connection Strategy |
| :--- | :--- | :--- | :--- |
| **Jenkins Master** | c7i-flex.large | Jenkins Core | Managed Web UI / Port 8080 |
| **Jenkins Build Agent (node1)** | c7i-flex.large | Docker Engine, Git | Private IP / SSH (Master to Agent) |
| **SonarQube Server** | c7i-flex.large | SonarQube, Nginx Proxy | Private IP / Port 80 (Proxied from 9000) |
| **Deployment Server** | t3.micro | Docker Engine, Node Exporter | Private IP / SSH Agent via Jenkins |
| **Monitoring Server** | t3.medium | Prometheus, Grafana | Scrapes metrics from targets via Port 9100 |

---

## 🚀 CI/CD Pipeline Workflow
The automation workflow is defined natively inside a declarative `Jenkinsfile` and executes the following sequential stages:

1. **Webhook Trigger**: A GitHub Webhook detects changes on the `main` branch and instantly initiates the pipeline loop.
2. **Code Checkout**: The Jenkins Build Agent (`node1`) pulls the latest source code from the repository.
3. **SonarQube Static Analysis**: Code quality, test inclusions, and static application security analyses (SAST) are processed on the build agent node and securely pushed via API to the SonarQube dashboard through an Nginx reverse proxy. A **Quality Gate Hook** blocks the build if bugs or critical vulnerabilities are discovered.
4. **Docker Multi-Stage Build**: The pipeline executes an optimized multi-stage `Dockerfile` to compile dependencies and create a lightweight, minimal container image.
5. **Registry Push**: The image is uniquely tagged with the Jenkins build number (`:build-${env.BUILD_NUMBER}`) and `:latest`, then securely uploaded to Docker Hub.
6. **Continuous Deployment (CD)**: Jenkins uses `sshagent` to securely tunnel into the Deployment Server over the AWS private network, pulls the fresh image, clean-replaces the old container instance, and provisions the live application.
7. **Automated Post-Deployment Health Check**: The pipeline pauses for 5 seconds to let the container network initialize, then runs an automated HTTP header inspection (`cURL`) against the deployment target. The pipeline explicitly fails if the target returns anything other than an **HTTP 200 OK**.
8. **ChatOps Notifications (Post-Build)**: An automated Jenkins `post` hook triggers a **Slack Webhook**. It dispatches a vibrant green workspace alert (`#00FF00`) on success, or a critical red failure alert (`#FF0000`) with direct console log troubleshooting links to developers.

---

## 📈 Monitoring & Automated Maintenance
Operational reliability and hosting health are sustained long after the deployment loop ends through two decoupled automated systems:

### 1. Centralized Telemetry Tracking
* **Prometheus & Grafana**: A dedicated monitoring server continuously pulls host hardware metrics (CPU spikes, memory thresholds, Disk IO) from `node_exporter` targets running on the infrastructure instances.
* **Grafana Dashboards**: Visualizes real-time performance profiles to safeguard against host node exhaustion.

### 2. Automated Log Management & Cloud Archiving
A automated background maintenance cycle handles server housecleaning using a Linux `cron` utility.
* **Storage Optimization**: The system sweeps and runs `docker image prune -f` alongside `docker container prune -f` every single night to destroy orphaned image layers and prevent disk space exhaustion.
* **AWS S3 Cloud Archiving**: A custom Bash script compresses local application logs (`.tar.gz`), appends an immutable timestamp, and securely transfers them into an encrypted **AWS S3 Bucket** via the AWS CLI utilizing a credential-less **AWS IAM Instance Profile Role**.

---

## 🔧 Infrastructure & Local Setup

### Prerequisites
* Ensure all EC2 AWS Security Groups strictly whitelist internal traffic over Private IPs (e.g., allowing port 9100 traffic exclusively from the Prometheus Server, and port 22 from the Jenkins Master).
* The SonarQube server must have port 9000 proxied through Nginx on Port 80.
* The Jenkins Build Agent system user (`ubuntu`) must belong to the host server's local `docker` group (`sudo usermod -aG docker jenkins`).

### Required Jenkins Credentials
The pipeline relies on the following global keys configured securely inside the Jenkins Master Dashboard:

* `sonar_key` (*Secret text*): SonarQube analysis authentication token.
* `dockerhub_creds` (*Username with password*): Docker Hub account registry authorization keys.
* `deployment_server_ssh` (*SSH Username with private key*): AWS `.pem` security private key for programmatic deployment server SSH tunnels.
* `slack_token` (*Secret text*): Secure webhook endpoint string providing safe Slack channel payload entry.

---

## 💾 Automated Maintenance Configuration

### The Backup Script (`backup_cleanup.sh`)
Deploy this script to `/home/ubuntu/scripts/backup_cleanup.sh` on your app host machine to process scheduled disk space reclamation and cloud uploads:

```bash
#!/bin/bash
S3_BUCKET="s3://your-devops-capstone-logs-bucket"
LOCAL_BACKUP_DIR="/home/ubuntu/backups"
LOG_DIR="/var/log/myapp"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p "$LOCAL_BACKUP_DIR"

# 1. Archive logs
tar -czf "$LOCAL_BACKUP_DIR/app_logs_$TIMESTAMP.tar.gz" -C "$LOG_DIR" .

# 2. Upload to S3 via IAM Role authentication
aws s3 cp "$LOCAL_BACKUP_DIR/" "$S3_BUCKET/archive/" --recursive --exclude "*" --include "*_$TIMESTAMP.tar.gz"

# 3. Clean local staging files and reclaim Docker storage space
rm -f "$LOCAL_BACKUP_DIR/*_$TIMESTAMP.tar.gz"
docker image prune -f
docker container prune -f
```

### Automation Cron Schedule
To trigger this housecleaning automatically every night at **2:00 AM**, install this configuration block into the host machine crontab (`crontab -e`):
```text
0 2 * * * /bin/bash /home/ubuntu/scripts/backup_cleanup.sh >> /var/log/cron_maintenance.log 2>&1
```
