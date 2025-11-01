# JB CI/CD Project - Terraform Infrastructure with GitOps

**Author:** Alexander Yasheyev  
**Institution:** JB College  
**Course:** CI/CD & DevOps  

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
- [Architecture](#-architecture)
- [Technologies Used](#-technologies-used)
- [Infrastructure Components](#-infrastructure-components)
- [Prerequisites](#-prerequisites)
- [Project Structure](#-project-structure)
- [Setup Instructions](#-setup-instructions)
- [Deployment Flow](#-deployment-flow)
- [Accessing the Application](#-accessing-the-application)
- [Monitoring & Troubleshooting](#-monitoring--troubleshooting)
- [Cost Analysis](#-cost-analysis)
- [Security Considerations](#-security-considerations)
- [Cleanup](#-cleanup)
- [Learning Outcomes](#-learning-outcomes)
- [References](#-references)

---

## 🎯 Project Overview

This project demonstrates a complete **Infrastructure as Code (IaC)** and **GitOps** implementation using modern DevOps tools. It automatically provisions an AWS EC2 instance, installs a Kubernetes cluster (K3s), deploys Argo CD for continuous deployment, and runs a custom AWS Resources Viewer application.

### Key Features

✅ **Infrastructure as Code** - Terraform manages all AWS resources  
✅ **GitOps Workflow** - Argo CD automatically syncs from Git repository  
✅ **Kubernetes Orchestration** - K3s lightweight Kubernetes distribution  
✅ **Automated Deployment** - Complete setup with single `terraform apply`  
✅ **AWS Integration** - Application queries and displays AWS resources  
✅ **Security Best Practices** - Secrets management, IP restrictions, IAM integration  

---

## 🏗️ Architecture

### High-Level Architecture

```mermaid
graph TB
    subgraph "AWS Cloud - us-east-1"
        subgraph "VPC - Default or Custom"
            subgraph "Public Subnet"
                EC2["EC2 Instance<br/>t3.medium<br/>Ubuntu 22.04"]
                
                subgraph "K3s Cluster"
                    subgraph "argocd namespace"
                        ArgoCD["Argo CD<br/>- Server<br/>- Repo Server<br/>- App Controller"]
                    end
                    
                    subgraph "default namespace"
                        App["AWS Resources Viewer<br/>NodePort: 30080"]
                        Secret["Secret: aws-credentials"]
                    end
                end
            end
            
            SG["Security Group<br/>jb-project-sg"]
            IGW["Internet Gateway"]
        end
    end
    
    GitHub["GitHub Repository<br/>jb-gitops<br/>(Helm Charts)"]
    DockerHub["Docker Hub<br/>formy5000/resources_viewer"]
    User["User<br/>(Your IP)"]
    Internet["Internet"]
    
    User -->|SSH:22| SG
    Internet -->|App:30080| SG
    Internet -->|ArgoCD:30443| SG
    SG --> EC2
    EC2 --> IGW
    IGW --> Internet
    ArgoCD -->|Syncs| GitHub
    App -->|Pulls Image| DockerHub
    App -->|Uses| Secret
    ArgoCD -->|Deploys| App

    style EC2 fill:#ff9900
    style ArgoCD fill:#ff6b6b
    style App fill:#4ecdc4
    style GitHub fill:#333
    style DockerHub fill:#2496ed
```

### GitOps Workflow

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as GitHub<br/>jb-gitops
    participant Argo as Argo CD
    participant K3s as K3s Cluster
    participant App as Application

    Dev->>Git: 1. Push Helm chart changes
    Note over Git: values.yaml updated
    
    Argo->>Git: 2. Poll for changes (every 3 min)
    Git-->>Argo: New commit detected
    
    Argo->>Argo: 3. Compare desired vs current state
    Note over Argo: Diff calculation
    
    Argo->>K3s: 4. Apply changes
    Note over K3s: Create/Update resources
    
    K3s->>App: 5. Deploy/Update pods
    App-->>K3s: Running
    
    K3s-->>Argo: 6. Report status
    Argo-->>Dev: Sync complete
    
    Note over Argo,App: Self-Healing: If pods crash,<br/>Argo CD recreates them
```

### Deployment Flow

```mermaid
flowchart TD
    Start([terraform apply]) --> TF[Terraform Execution]
    
    TF --> VPC{Default VPC<br/>exists?}
    VPC -->|Yes| UseDefault[Use Default VPC]
    VPC -->|No| CreateVPC[Create VPC<br/>CIDR: 10.0.0.0/16]
    
    UseDefault --> SG[Create Security Group]
    CreateVPC --> IGW[Create Internet Gateway]
    IGW --> Subnet[Create Subnet<br/>CIDR: 10.0.1.0/24]
    Subnet --> RT[Create Route Table]
    RT --> SG
    
    SG --> KeyPair[Create Key Pair<br/>from ~/.ssh/id_rsa.pub]
    KeyPair --> EC2[Launch EC2 Instance<br/>t3.medium, Ubuntu 22.04]
    
    EC2 --> UserData[Execute user-data.sh]
    
    UserData --> Update[System Update<br/>apt-get update & upgrade]
    Update --> InstallK3s[Install K3s<br/>curl -sfL https://get.k3s.io]
    InstallK3s --> WaitK3s[Wait for K3s Ready<br/>60 seconds]
    
    WaitK3s --> Tools[Install Tools<br/>kubectl, Helm]
    Tools --> CreateSecret[Create AWS Secret<br/>in default namespace]
    
    CreateSecret --> InstallArgo[Install Argo CD<br/>in argocd namespace]
    InstallArgo --> WaitArgo[Wait for Argo CD Pods<br/>up to 15 minutes]
    
    WaitArgo --> PatchArgo[Patch Argo CD Service<br/>NodePort: 30443]
    PatchArgo --> GetPass[Save Argo CD Password<br/>to /home/ubuntu/argocd-password.txt]
    
    GetPass --> CreateApp[Create Argo CD Application<br/>pointing to jb-gitops repo]
    CreateApp --> ArgoSync[Argo CD Syncs<br/>Deploys Helm chart]
    
    ArgoSync --> AppRunning[Application Running<br/>NodePort: 30080]
    AppRunning --> Complete([✅ Deployment Complete])
    
    style Start fill:#90EE90
    style Complete fill:#90EE90
    style EC2 fill:#ff9900
    style InstallArgo fill:#ff6b6b
    style AppRunning fill:#4ecdc4
```

### Network Flow

```mermaid
flowchart LR
    subgraph Internet
        User[User Browser]
        SSH[SSH Client]
    end
    
    subgraph "AWS Security Group"
        Rule1[SSH: 22<br/>Your IP Only]
        Rule2[K3s API: 6443<br/>0.0.0.0/0]
        Rule3[App: 30080<br/>0.0.0.0/0]
        Rule4[Argo CD: 30443<br/>0.0.0.0/0]
    end
    
    subgraph "EC2 Instance"
        subgraph "K3s Services"
            AppSvc[Service: aws-resources-viewer<br/>Type: NodePort<br/>Port: 30080]
            ArgoSvc[Service: argocd-server<br/>Type: NodePort<br/>Port: 30443]
        end
        
        subgraph "Pods"
            AppPod[Pod: resources-viewer<br/>Container Port: 5000<br/>Env: AWS Credentials]
        end
    end
    
    subgraph "AWS APIs"
        EC2API[EC2 API]
        S3API[S3 API]
        RDSAPI[RDS API]
    end
    
    User -->|HTTP:30080| Rule3
    User -->|HTTPS:30443| Rule4
    SSH -->|SSH:22| Rule1
    
    Rule3 --> AppSvc
    Rule4 --> ArgoSvc
    Rule1 --> EC2Instance[SSH Access]
    
    AppSvc --> AppPod
    AppPod -->|AWS SDK Calls| EC2API
    AppPod -->|AWS SDK Calls| S3API
    AppPod -->|AWS SDK Calls| RDSAPI
    
    style User fill:#4ecdc4
    style AppPod fill:#4ecdc4
    style Rule1 fill:#ff6b6b
    style Rule3 fill:#90EE90
```

---

## 🛠️ Technologies Used

| Technology | Version | Purpose |
|------------|---------|---------|
| **Terraform** | ≥ 1.0 | Infrastructure as Code - Provisions AWS resources |
| **AWS EC2** | - | Cloud compute instance hosting the cluster |
| **K3s** | Latest | Lightweight Kubernetes distribution |
| **Argo CD** | Stable | GitOps continuous deployment tool |
| **Helm** | 3.x | Kubernetes package manager |
| **Docker** | - | Container runtime (via K3s) |
| **Ubuntu** | 22.04 LTS | Operating system |
| **GitHub** | - | Git repository for GitOps |
| **AWS SDK** | boto3 | Application queries AWS resources |

---

## 🧩 Infrastructure Components

### 1. VPC & Networking
- **VPC**: Automatically uses default VPC if available, creates new one (10.0.0.0/16) if not
- **Subnet**: Public subnet (10.0.1.0/24) with auto-assign public IP
- **Internet Gateway**: Enables internet connectivity (only if VPC created)
- **Route Table**: Routes traffic to internet gateway (0.0.0.0/0)

### 2. Security Group (`jb-project-sg`)
Firewall rules controlling access:
- **Port 22 (SSH)**: Restricted to your IP only (configured via `your_ip` variable)
- **Port 6443 (K3s API)**: Open to 0.0.0.0/0 for Kubernetes API access
- **Port 30080 (Application)**: Open to 0.0.0.0/0 for public web app access
- **Port 30443 (Argo CD UI)**: Open to 0.0.0.0/0 for Argo CD dashboard access
- **Egress**: All outbound traffic allowed

### 3. EC2 Instance
- **Type**: t3.medium (2 vCPU, 4GB RAM) - configurable via `instance_type` variable
- **AMI**: Ubuntu 22.04 LTS (latest, automatically fetched)
- **Storage**: 20GB GP3 EBS volume
- **Key Pair**: Uses your local SSH key from `~/.ssh/id_rsa.pub`
- **User Data**: Automated bootstrap script (`user-data.sh`)

### 4. K3s Cluster
Lightweight Kubernetes with:
- Single-node cluster configuration
- Built-in container runtime (containerd)
- Traefik ingress controller (default)
- CoreDNS for service discovery
- Kubeconfig at `/etc/rancher/k3s/k3s.yaml`

### 5. Argo CD
GitOps deployment tool:
- Monitors Git repository: `https://github.com/githuber20202/jb-gitops.git`
- Automatically syncs Kubernetes manifests every 3 minutes
- Self-healing enabled (recreates failed pods)
- Auto-pruning enabled (removes deleted resources)
- Web UI exposed on NodePort 30443

### 6. Application (AWS Resources Viewer)
- **Image**: `formy5000/resources_viewer` from Docker Hub
- **Language**: Python Flask application
- **Features**: Displays AWS resources (EC2, S3, RDS, etc.)
- **Authentication**: Uses AWS credentials from Kubernetes secret
- **Deployment**: Via Helm chart from jb-gitops repository
- **Exposure**: NodePort service on port 30080

---

## 📦 Prerequisites

### Required Tools

1. **Terraform** (≥ 1.0)
   ```bash
   # Install on Windows (using Chocolatey)
   choco install terraform
   
   # Install on macOS
   brew install terraform
   
   # Install on Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Verify installation
   terraform version
   ```

2. **AWS CLI** (configured with credentials)
   ```bash
   # Install
   pip install awscli
   
   # Configure with your Terraform AWS credentials
   aws configure
   # Enter: Access Key, Secret Key, Region (us-east-1), Output format (json)
   
   # Verify
   aws sts get-caller-identity
   ```

3. **SSH Key Pair**
   ```bash
   # Generate if you don't have one
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   
   # Verify public key exists
   cat ~/.ssh/id_rsa.pub
   ```

### AWS Requirements

- **AWS Account** with appropriate permissions
- **IAM User** with programmatic access for Terraform
- **Permissions needed for Terraform**:
  - EC2: Full access (create instances, security groups, key pairs)
  - VPC: Full access (create VPC, subnets, internet gateways, route tables)
  - Read access to availability zones and AMIs

### Application AWS Credentials

The application needs **separate** AWS credentials to query resources:
- Create an IAM user with **ReadOnlyAccess** policy (or specific read permissions)
- Generate access keys for this user
- These credentials will be stored as Kubernetes secrets (not in Git!)
- **Important**: These are different from your Terraform AWS credentials

---

## 📁 Project Structure

```
jb-terraform/
├── main.tf                 # Main infrastructure definition
│   ├── Data sources (AMI, VPC, subnets)
│   ├── VPC & Networking (conditional creation)
│   ├── Security Group (jb-project-sg)
│   ├── Key Pair (from ~/.ssh/id_rsa.pub)
│   └── EC2 Instance with user data
│
├── variables.tf            # Input variables
│   ├── aws_region (default: us-east-1)
│   ├── instance_type (default: t3.medium)
│   ├── project_name (default: jb-project)
│   ├── your_ip (required - your public IP)
│   ├── gitops_repo (default: jb-gitops)
│   ├── docker_image (default: formy5000/resources_viewer)
│   ├── aws_access_key_id (sensitive)
│   ├── aws_secret_access_key (sensitive)
│   └── aws_app_region (default: us-east-1)
│
├── outputs.tf              # Output values
│   ├── instance_id
│   ├── instance_public_ip
│   ├── app_url (http://<IP>:30080)
│   ├── argocd_url (https://<IP>:30443)
│   ├── ssh_command
│   └── important_info (formatted summary)
│
├── provider.tf             # AWS provider configuration
│   └── AWS provider with region
│
├── user-data.sh            # EC2 bootstrap script
│   ├── System updates (apt-get)
│   ├── K3s installation
│   ├── kubectl & Helm installation
│   ├── AWS credentials secret creation
│   ├── Argo CD installation
│   ├── Argo CD service patching (NodePort)
│   ├── Argo CD Application creation
│   └── Info files generation
│
├── terraform.tfvars        # Variable values (gitignored)
│   └── Contains sensitive data - DO NOT COMMIT
│
├── .gitignore              # Git ignore rules
│   ├── *.tfstate*
│   ├── *.tfvars
│   ├── .terraform/
│   └── .terraform.lock.hcl
│
└── Readme.md               # This file
```

---

## 🚀 Setup Instructions

### Step 1: Clone the Repository

```bash
git clone https://github.com/githuber20202/jb-terraform.git
cd jb-terraform
```

### Step 2: Create terraform.tfvars

Create a file named `terraform.tfvars` with your values:

```hcl
# Your public IP for SSH access (find it at https://whatismyip.com)
# IMPORTANT: Must include /32 suffix
your_ip = "82.166.123.45/32"

# AWS credentials for the application (NOT your Terraform credentials)
# These should be from an IAM user with ReadOnlyAccess policy
aws_access_key_id     = "AKIAIOSFODNN7EXAMPLE"
aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
aws_app_region        = "us-east-1"

# Optional: Override defaults if needed
# aws_region      = "us-east-1"
# instance_type   = "t3.medium"
# project_name    = "jb-project"
# gitops_repo     = "https://github.com/githuber20202/jb-gitops.git"
# docker_image    = "formy5000/resources_viewer"
```

**⚠️ Security Note**: This file is in `.gitignore` and will NOT be committed to Git!

### Step 3: Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and initializes the backend.

**Expected output:**
```
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.x.x...

Terraform has been successfully initialized!
```

### Step 4: Validate Configuration

```bash
terraform validate
```

**Expected output:**
```
Success! The configuration is valid.
```

### Step 5: Plan the Deployment

```bash
terraform plan
```

Review the resources that will be created. Terraform will show:
- VPC components (if default VPC doesn't exist)
- Security group with 4 ingress rules
- Key pair
- EC2 instance with user data

**Expected output:**
```
Plan: 5 to add, 0 to change, 0 to destroy.
(or 8-10 if creating VPC)

Changes to Outputs:
  + app_url            = "http://<IP>:30080"
  + argocd_url         = "https://<IP>:30443"
  + important_info     = <<-EOT
        ...
    EOT
  + instance_id        = "<instance-id>"
  + instance_public_ip = "<IP>"
  + ssh_command        = "ssh -i ~/.ssh/id_rsa ubuntu@<IP>"
```

### Step 6: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time**: 
- Terraform execution: ~2-3 minutes
- User data script: ~5-10 minutes
- Total: ~10-15 minutes

**Expected output:**
```
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

important_info = <<EOT

========================================
🎉 Alexander Yasheyev JB CI-CD Project Deployed!
========================================

📦 Application:
   http://54.123.45.67:30080

🚀 Argo CD UI:
   https://54.123.45.67:30443
   Username: admin
   Password: SSH to instance and run:
            cat /home/ubuntu/argocd-password.txt

💻 SSH:
   ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67

📋 Cluster Info:
   cat /home/ubuntu/cluster-info.txt

⏰ Wait 5-10 minutes for full setup!

========================================
EOT
```

### Step 7: Monitor Deployment Progress

```bash
# SSH to the instance
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>

# Watch the user-data script execution
tail -f /var/log/user-data.log

# Check when setup is complete (look for "Setup Complete!" message)
```

---

## 🔄 Deployment Flow

### Timeline

```mermaid
gantt
    title Deployment Timeline
    dateFormat mm:ss
    axisFormat %M:%S
    
    section Terraform
    terraform apply           :00:00, 03:00
    
    section User Data Script
    System Update            :03:00, 02:00
    Install K3s              :05:00, 02:00
    Wait for K3s             :07:00, 01:00
    Install Tools            :08:00, 01:00
    Create Secret            :09:00, 00:10
    Install Argo CD          :09:10, 03:00
    Wait for Argo CD         :12:10, 02:00
    Configure Argo CD        :14:10, 00:30
    Create Application       :14:40, 00:20
    Argo CD Sync             :15:00, 01:00
    
    section Ready
    Application Running      :16:00, 00:00
```

### Detailed Process

1. **Terraform Execution (0-3 min)**
   - Creates/validates VPC and networking
   - Creates security group with firewall rules
   - Uploads SSH public key
   - Launches EC2 instance
   - Attaches user-data script

2. **System Setup (3-5 min)**
   - Updates Ubuntu packages (`apt-get update && upgrade`)
   - Installs prerequisites (curl, git)

3. **K3s Installation (5-8 min)**
   - Downloads and installs K3s
   - Configures kubeconfig at `/etc/rancher/k3s/k3s.yaml`
   - Waits for node to be ready
   - Sets up kubectl for ubuntu user

4. **Tools Installation (8-9 min)**
   - Installs kubectl binary
   - Installs Helm 3

5. **Secret Creation (9 min)**
   - Creates Kubernetes secret `aws-credentials` in default namespace
   - Contains: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION

6. **Argo CD Installation (9-14 min)**
   - Creates argocd namespace
   - Applies Argo CD manifests from official repository
   - Waits for all Argo CD pods to be ready (can take up to 15 min)
   - Patches argocd-server service to NodePort 30443
   - Retrieves and saves admin password

7. **Application Deployment (14-16 min)**
   - Creates Argo CD Application CRD
   - Points to GitHub repository: jb-gitops
   - Enables auto-sync and self-heal
   - Argo CD clones repository and renders Helm chart
   - Deploys application to default namespace
   - Application pulls Docker image and starts

8. **Completion (16 min)**
   - Application accessible at http://<IP>:30080
   - Argo CD UI accessible at https://<IP>:30443
   - All logs available in `/var/log/user-data.log`

---

## 🌐 Accessing the Application

### 1. Application URL

```
http://<EC2_PUBLIC_IP>:30080
```

**Features:**
- View AWS EC2 instances in configured region
- View S3 buckets
- View RDS databases
- View other AWS resources
- Real-time data from AWS APIs

**Note**: Application uses credentials from the Kubernetes secret to query AWS.

### 2. Argo CD UI

```
https://<EC2_PUBLIC_IP>:30443
```

**Login Credentials:**
- **Username**: `admin`
- **Password**: Retrieve via SSH:
  ```bash
  ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>
  cat /home/ubuntu/argocd-password.txt
  ```

**Argo CD Dashboard Features:**
- Application sync status (Synced/OutOfSync)
- Git repository connection status
- Kubernetes resources tree view
- Sync history and logs
- Health status of all components
- Manual sync trigger
- Diff view between Git and cluster

### 3. SSH Access

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>
```

**Useful Commands:**

```bash
# View cluster information
cat /home/ubuntu/cluster-info.txt

# View Argo CD password
cat /home/ubuntu/argocd-password.txt

# Check all pods across all namespaces
kubectl get pods -A

# Check Argo CD application status
kubectl get app -n argocd

# Describe Argo CD application for details
kubectl describe app aws-resources-viewer -n argocd

# View application logs
kubectl logs -n default -l app=aws-resources-viewer

# Check application deployment
kubectl get deployment -n default

# View services
kubectl get svc -A

# Check nodes
kubectl get nodes

# View events
kubectl get events -A --sort-by='.lastTimestamp'

# Check K3s service status
sudo systemctl status k3s

# View user-data script logs
tail -f /var/log/user-data.log

# Check secret
kubectl get secret aws-credentials -n default -o yaml
```

---

## 🔍 Monitoring & Troubleshooting

### Check Deployment Progress

```bash
# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>

# Watch user-data script execution in real-time
tail -f /var/log/user-data.log

# Check if K3s is running
sudo systemctl status k3s

# Check all pods
kubectl get pods -A

# Check Argo CD application
kubectl get app -n argocd

# Wait for application to be synced
kubectl wait --for=condition=Synced app/aws-resources-viewer -n argocd --timeout=300s
```

### Common Issues & Solutions

#### 1. Application Not Loading (Connection Refused)

**Symptoms:** Browser shows "Connection refused" or timeout at port 30080

**Diagnosis:**
```bash
# Check if pods are running
kubectl get pods -n default

# Check pod status
kubectl describe pod -n default -l app=aws-resources-viewer

# Check pod logs
kubectl logs -n default -l app=aws-resources-viewer

# Check service
kubectl get svc -n default

# Verify NodePort
kubectl get svc aws-resources-viewer -n default -o jsonpath='{.spec.ports[0].nodePort}'
```

**Solutions:**
- Wait longer (application may still be pulling Docker image)
- Check if Argo CD has synced: `kubectl get app -n argocd`
- Manually trigger sync: `kubectl patch app aws-resources-viewer -n argocd --type merge -p '{"operation":{"sync":{}}}'`
- Check security group allows port 30080

#### 2. Argo CD Not Syncing

**Symptoms:** Application shows "OutOfSync" in Argo CD UI

**Diagnosis:**
```bash
# Check Argo CD application status
kubectl get app -n argocd

# Describe application for detailed status
kubectl describe app aws-resources-viewer -n argocd

# Check Argo CD server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Check repo server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

**Solutions:**
- Verify Git repository is accessible
- Check if Helm chart path is correct (aws-resources-viewer)
- Manually trigger sync via UI or CLI
- Check Argo CD has internet access

#### 3. AWS Credentials Error

**Symptoms:** Application shows "Unable to locate credentials" or "Access Denied"

**Diagnosis:**
```bash
# Check if secret exists
kubectl get secret aws-credentials -n default

# Verify secret contents (base64 encoded)
kubectl get secret aws-credentials -n default -o yaml

# Check if pod has environment variables
kubectl describe pod -n default -l app=aws-resources-viewer | grep -A 10 Environment

# Check pod logs for credential errors
kubectl logs -n default -l app=aws-resources-viewer | grep -i credential
```

**Solutions:**
- Verify credentials in terraform.tfvars are correct
- Ensure IAM user has ReadOnlyAccess policy
- Recreate secret:
  ```bash
  kubectl delete secret aws-credentials -n default
  # Then re-run user-data script section or manually create secret
  ```

#### 4. SSH Connection Refused

**Symptoms:** Cannot SSH to instance

**Diagnosis:**
```bash
# Check if instance is running
aws ec2 describe-instances --instance-ids <instance-id>

# Check security group rules
aws ec2 describe-security-groups --group-ids <sg-id>

# Verify your current IP
curl https://api.ipify.org
```

**Solutions:**
- Verify your IP hasn't changed
- Update security group if IP changed:
  ```bash
  # Via Terraform
  # Update your_ip in terraform.tfvars and run:
  terraform apply
  
  # Or via AWS CLI
  aws ec2 authorize-security-group-ingress \
    --group-id <sg-id> \
    --protocol tcp \
    --port 22 \
    --cidr <NEW_IP>/32
  ```
- Check SSH key permissions: `chmod 600 ~/.ssh/id_rsa`

#### 5. K3s Not Starting

**Symptoms:** K3s service fails to start

**Diagnosis:**
```bash
# Check K3s service status
sudo systemctl status k3s

# View K3s logs
sudo journalctl -u k3s -n 100

# Check if port 6443 is available
sudo netstat -tulpn | grep 6443
```

**Solutions:**
- Restart K3s: `sudo systemctl restart k3s`
- Check system resources: `free -h` and `df -h`
- Ensure instance type has enough resources (t3.medium recommended)

#### 6. Argo CD Pods Not Ready

**Symptoms:** Argo CD pods stuck in Pending or CrashLoopBackOff

**Diagnosis:**
```bash
# Check all Argo CD pods
kubectl get pods -n argocd

# Describe problematic pod
kubectl describe pod <pod-name> -n argocd

# Check pod logs
kubectl logs <pod-name> -n argocd
```

**Solutions:**
- Wait longer (Argo CD can take 10-15 minutes to fully start)
- Check node resources: `kubectl describe node`
- Restart pod: `kubectl delete pod <pod-name> -n argocd`

### Health Check Commands

```bash
# Overall cluster health
kubectl get nodes
kubectl get pods -A
kubectl get svc -A

# Argo CD health
kubectl get pods -n argocd
kubectl get app -n argocd

# Application health
kubectl get deployment -n default
kubectl get pods -n default
kubectl get svc -n default

# View recent events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Check resource usage
kubectl top nodes
kubectl top pods -A
```

---

## 💰 Cost Analysis

### AWS Free Tier Considerations

| Resource | Free Tier | This Project | Monthly Cost |
|----------|-----------|--------------|--------------|
| **EC2 Instance** | 750
