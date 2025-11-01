#  JB CI/CD Project - Terraform Infrastructure with GitOps

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

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Cloud (us-east-1)                       │
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    VPC (Default or Custom)                    │   │
│  │                                                                │   │
│  │  ┌──────────────────────────────────────────────────────┐   │   │
│  │  │              Public Subnet                            │   │   │
│  │  │                                                        │   │   │
│  │  │  ┌──────────────────────────────────────────────┐   │   │   │
│  │  │  │   EC2 Instance (t3.medium)                   │   │   │   │
│  │  │  │   Ubuntu 22.04 LTS                           │   │   │   │
│  │  │  │                                               │   │   │   │
│  │  │  │  ┌────────────────────────────────────┐     │   │   │   │
│  │  │  │  │     K3s Kubernetes Cluster         │     │   │   │   │
│  │  │  │  │                                     │     │   │   │   │
│  │  │  │  │  ┌──────────────────────────┐     │     │   │   │   │
│  │  │  │  │  │   Argo CD (argocd ns)    │     │     │   │   │   │
│  │  │  │  │  │   - Server                │     │     │   │   │   │
│  │  │  │  │  │   - Repo Server           │     │     │   │   │   │
│  │  │  │  │  │   - Application Controller│     │     │   │   │   │
│  │  │  │  │  └──────────────────────────┘     │     │   │   │   │
│  │  │  │  │                                     │     │   │   │   │
│  │  │  │  │  ┌──────────────────────────┐     │     │   │   │   │
│  │  │  │  │  │  App (default ns)         │     │     │   │   │   │
│  │  │  │  │  │  - AWS Resources Viewer   │     │     │   │   │   │
│  │  │  │  │  │  - NodePort: 30080        │     │     │   │   │   │
│  │  │  │  │  └──────────────────────────┘     │     │   │   │   │
│  │  │  │  └────────────────────────────────────┘     │   │   │   │
│  │  │  │                                               │   │   │   │
│  │  │  │  Ports:                                       │   │   │   │
│  │  │  │  - 22 (SSH) ← Your IP Only                   │   │   │   │
│  │  │  │  - 6443 (K3s API)                            │   │   │   │
│  │  │  │  - 30080 (App) ← Public                      │   │   │   │
│  │  │  │  - 30443 (Argo CD UI) ← Public               │   │   │   │
│  │  │  └──────────────────────────────────────────────┘   │   │   │
│  │  │                                                        │   │   │
│  │  └────────────────────────────────────────────────────────┘   │   │
│  │                                                                │   │
│  │  Security Group: jb-project-sg                                │   │
│  │  Internet Gateway: Routes to 0.0.0.0/0                        │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘

External Components:
┌──────────────────────┐         ┌──────────────────────┐
│  GitHub Repository   │         │   Docker Hub         │
│  jb-gitops           │────────▶│  formy5000/          │
│  (Helm Charts)       │         │  resources_viewer    │
└──────────────────────┘         └──────────────────────┘
         ▲
         │
    Argo CD Syncs
```

### GitOps Workflow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitOps Deployment Flow                       │
└─────────────────────────────────────────────────────────────────┘

1. Developer Push          2. Argo CD Detects       3. Argo CD Syncs
   ┌──────────┐               ┌──────────┐             ┌──────────┐
   │   Git    │──────────────▶│  Argo CD │────────────▶│   K3s    │
   │  Commit  │   Changes     │  Watches │   Applies   │ Cluster  │
   └──────────┘               └──────────┘             └──────────┘
        │                           │                        │
        │                           │                        │
        ▼                           ▼                        ▼
   Helm Charts              Compares Desired          Pods Running
   values.yaml              vs Current State          Application Live

4. Self-Healing: If pods crash or are deleted, Argo CD recreates them
5. Auto-Prune: Removed resources from Git are deleted from cluster
```

### Network Flow Diagram

```
┌──────────────┐
│   Internet   │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│            Internet Gateway                          │
└─────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│         Security Group (jb-project-sg)               │
│  Rules:                                              │
│  • SSH (22) ← Your IP Only                          │
│  • K3s API (6443) ← 0.0.0.0/0                       │
│  • App (30080) ← 0.0.0.0/0                          │
│  • Argo CD (30443) ← 0.0.0.0/0                      │
└─────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────┐
│              EC2 Instance                            │
│  ┌────────────────────────────────────────────┐    │
│  │  K3s Cluster                                │    │
│  │  ┌──────────────────────────────────────┐  │    │
│  │  │  Service: aws-resources-viewer       │  │    │
│  │  │  Type: NodePort                      │  │    │
│  │  │  Port: 30080                         │  │    │
│  │  │  ┌────────────────────────────────┐  │  │    │
│  │  │  │  Pod: resources-viewer         │  │  │    │
│  │  │  │  Container Port: 5000          │  │  │    │
│  │  │  │  Env: AWS_ACCESS_KEY_ID        │  │  │    │
│  │  │  │       AWS_SECRET_ACCESS_KEY    │  │  │    │
│  │  │  └────────────────────────────────┘  │  │    │
│  │  └──────────────────────────────────────┘  │    │
│  └────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
       │
       │ AWS SDK Calls
       ▼
┌─────────────────────────────────────────────────────┐
│         AWS APIs (EC2, S3, RDS, etc.)               │
│         Queries resources in specified region        │
└─────────────────────────────────────────────────────┘
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
| **AWS SDK** | - | Application queries AWS resources |

---

## 🧩 Infrastructure Components

### 1. **VPC & Networking**
- **VPC**: Uses default VPC if available, creates new one if not
- **Subnet**: Public subnet with auto-assign public IP
- **Internet Gateway**: Enables internet connectivity
- **Route Table**: Routes traffic to internet gateway

### 2. **Security Group**
Firewall rules controlling access:
- **Port 22 (SSH)**: Restricted to your IP only
- **Port 6443 (K3s API)**: Open for Kubernetes API access
- **Port 30080 (Application)**: Public access to web app
- **Port 30443 (Argo CD UI)**: Public access to Argo CD dashboard

### 3. **EC2 Instance**
- **Type**: t3.medium (2 vCPU, 4GB RAM)
- **AMI**: Ubuntu 22.04 LTS (latest)
- **Storage**: 20GB GP3 EBS volume
- **Key Pair**: Uses your local SSH key

### 4. **K3s Cluster**
Lightweight Kubernetes with:
- Single-node cluster
- Built-in container runtime
- Traefik ingress controller
- CoreDNS for service discovery

### 5. **Argo CD**
GitOps deployment tool:
- Monitors Git repository for changes
- Automatically syncs Kubernetes manifests
- Self-healing and auto-pruning enabled
- Web UI for visualization

### 6. **Application**
AWS Resources Viewer:
- Python Flask application
- Displays AWS resources (EC2, S3, RDS, etc.)
- Uses AWS SDK with provided credentials
- Deployed via Helm chart

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
   ```

2. **AWS CLI** (configured)
   ```bash
   # Install
   pip install awscli
   
   # Configure
   aws configure
   # Enter: Access Key, Secret Key, Region (us-east-1), Output format (json)
   ```

3. **SSH Key Pair**
   ```bash
   # Generate if you don't have one
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

### AWS Requirements

- **AWS Account** with appropriate permissions
- **IAM User** with programmatic access
- **Permissions needed**:
  - EC2 (create instances, security groups, key pairs)
  - VPC (create VPC, subnets, internet gateways)
  - IAM (for application to query AWS resources)

### Application AWS Credentials

The application needs AWS credentials to query resources:
- Create an IAM user with **ReadOnlyAccess** policy
- Generate access keys for this user
- These will be stored as Kubernetes secrets (not in Git!)

---

## 📁 Project Structure

```
jb-terraform/
├── main.tf                 # Main infrastructure definition
│   ├── VPC & Networking
│   ├── Security Groups
│   ├── EC2 Instance
│   └── User Data template
│
├── variables.tf            # Input variables
│   ├── AWS region
│   ├── Instance type
│   ├── Your IP address
│   ├── GitOps repository
│   └── AWS credentials (sensitive)
│
├── outputs.tf              # Output values
│   ├── Instance IP
│   ├── Application URL
│   ├── Argo CD URL
│   └── SSH command
│
├── provider.tf             # AWS provider configuration
│
├── user-data.sh            # EC2 bootstrap script
│   ├── System updates
│   ├── K3s installation
│   ├── Argo CD installation
│   ├── Secret creation
│   └── Application deployment
│
├── terraform.tfvars        # Variable values (gitignored)
│   └── Contains sensitive data
│
├── .gitignore              # Git ignore rules
│   ├── *.tfstate
│   ├── *.tfvars
│   └── .terraform/
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
your_ip = "82.166.123.45/32"

# AWS credentials for the application (NOT your Terraform credentials)
aws_access_key_id     = "AKIAIOSFODNN7EXAMPLE"
aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
aws_app_region        = "us-east-1"

# Optional: Override defaults
# aws_region      = "us-east-1"
# instance_type   = "t3.medium"
# project_name    = "jb-project"
```

**⚠️ Important**: This file is in `.gitignore` and will NOT be committed to Git!

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

### Step 4: Plan the Deployment

```bash
terraform plan
```

Review the resources that will be created:
- VPC components (if needed)
- Security group
- Key pair
- EC2 instance

**Expected output:**
```
Plan: 8 to add, 0 to change, 0 to destroy.
```

### Step 5: Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

**Deployment time**: ~2-3 minutes for Terraform, then 5-10 minutes for the application setup.

**Expected output:**
```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

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

---

## 🔄 Deployment Flow

### Detailed Step-by-Step Process

```
┌─────────────────────────────────────────────────────────────────┐
│                    Terraform Apply                               │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  1. Create VPC & Networking (if needed)                          │
│     • VPC with CIDR 10.0.0.0/16                                 │
│     • Public subnet                                              │
│     • Internet gateway                                           │
│     • Route table                                                │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  2. Create Security Group                                        │
│     • SSH (22) from your IP                                     │
│     • K3s API (6443) from anywhere                              │
│     • App (30080) from anywhere                                 │
│     • Argo CD (30443) from anywhere                             │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  3. Create Key Pair                                              │
│     • Upload your public SSH key                                │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  4. Launch EC2 Instance                                          │
│     • Ubuntu 22.04 LTS                                          │
│     • t3.medium                                                  │
│     • 20GB storage                                               │
│     • User data script attached                                 │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│              User Data Script Execution (5-10 min)               │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  5. System Setup                                                 │
│     • apt-get update && upgrade                                 │
│     • Install curl, git                                          │
│     Duration: ~2 minutes                                         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  6. Install K3s                                                  │
│     • Download and install K3s                                  │
│     • Configure kubeconfig                                       │
│     • Wait for node to be ready                                 │
│     Duration: ~2 minutes                                         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  7. Install Tools                                                │
│     • kubectl                                                    │
│     • Helm 3                                                     │
│     Duration: ~1 minute                                          │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  8. Create AWS Credentials Secret                                │
│     • Create Kubernetes secret in default namespace             │
│     • Contains: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY        │
│     Duration: <10 seconds                                        │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  9. Install Argo CD                                              │
│     • Create argocd namespace                                   │
│     • Apply Argo CD manifests                                   │
│     • Wait for all pods to be ready                             │
│     • Patch service to NodePort                                 │
│     • Save admin password                                        │
│     Duration: ~3 minutes                                         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  10. Create Argo CD Application                                  │
│      • Define Application CRD                                   │
│      • Point to GitHub repository                               │
│      • Enable auto-sync and self-heal                           │
│      Duration: <10 seconds                                       │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  11. Argo CD Syncs Application                                   │
│      • Clones Git repository                                    │
│      • Renders Helm chart                                       │
│      • Applies Kubernetes manifests                             │
│      • Creates deployment, service, etc.                        │
│      Duration: ~1 minute                                         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  12. Application Running                                         │
│      • Pod pulls Docker image                                   │
│      • Container starts                                          │
│      • Service exposes on NodePort 30080                        │
│      Duration: ~1 minute                                         │
└─────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ✅ Deployment Complete!                       │
│                                                                  │
│  • Application accessible at http://<IP>:30080                  │
│  • Argo CD UI at https://<IP>:30443                             │
│  • All logs in /var/log/user-data.log                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🌐 Accessing the Application

### 1. Application URL

```
http://<EC2_PUBLIC_IP>:30080
```

**Features:**
- View AWS EC2 instances
- View S3 buckets
- View RDS databases
- View other AWS resources in the configured region

### 2. Argo CD UI

```
https://<EC2_PUBLIC_IP>:30443
```

**Login:**
- **Username**: `admin`
- **Password**: SSH to instance and run:
  ```bash
  ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>
  cat /home/ubuntu/argocd-password.txt
  ```

**Argo CD Dashboard shows:**
- Application sync status
- Git repository connection
- Kubernetes resources
- Sync history
- Health status

### 3. SSH Access

```bash
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>
```

**Useful commands once connected:**
```bash
# View cluster info
cat /home/ubuntu/cluster-info.txt

# Check all pods
kubectl get pods -A

# Check Argo CD application
kubectl get app -n argocd

# View application logs
kubectl logs -n default -l app=aws-resources-viewer

# Check Argo CD sync status
kubectl describe app aws-resources-viewer -n argocd

# View user-data script logs
tail -f /var/log/user-data.log
```

---

## 🔍 Monitoring & Troubleshooting

### Check Deployment Progress

```bash
# SSH to instance
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_PUBLIC_IP>

# Watch user-data script execution
tail -f /var/log/user-data.log

# Check if K3s is running
sudo systemctl status k3s

# Check all pods
kubectl get pods -A

# Check Argo CD application
kubectl get app -n argocd
```

### Common Issues

#### 1. Application Not Loading

**Symptoms:** Browser shows "Connection refused" or timeout

**Solutions:**
```bash
# Check if pods are running
kubectl get pods -n default

# Check pod logs
kubectl logs -n default -l app=aws-resources-viewer

# Check service
kubectl get svc -n default

# Verify NodePort
kubectl get svc aws-resources-viewer -n default -o yaml | grep nodePort
```

#### 2. Argo CD Not Syncing

**Symptoms:** Application shows "OutOfSync" in Argo CD UI

**Solutions:**
```bash
# Check Argo CD application status
kubectl get app -n argocd

# Describe application for details
kubectl describe app aws-resources-viewer -n argocd

# Check Argo CD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Manually trigger sync
kubectl patch app aws-resources-viewer -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

#### 3. AWS Credentials Error

**Symptoms:** Application shows "Unable to locate credentials"

**Solutions:**
```bash
# Check if secret exists
kubectl get secret aws-credentials -n default

# Verify secret contents (base64 encoded)
kubectl get secret aws-credentials -n default -o yaml

# Check if pod has environment variables
kubectl describe pod -n default -l app=aws-resources-viewer | grep -A 5 Environment
```

#### 4. SSH Connection Refused

**Symptoms:** Cannot SSH to instance

**Solutions:**
- Verify your IP hasn't changed: https://whatismyip.com
- Update security group if needed:
  ```bash
  # Get security group ID
  terraform output | grep security_group
  
  # Update via AWS Console or CLI
  aws ec2 authorize-security-group-ingress \
    --group-id sg-xxxxx \
    --protocol tcp \
    --port 22 \
    --cidr <NEW_IP>/32
  ```

### Health Checks

```bash
# Check node status
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check services
kubectl get svc -A

# Check Argo CD health
kubectl get pods -n argocd

# Check application deployment
kubectl get deployment -n default

# View events
kubectl get events -A --sort-by='.lastTimestamp'
```

---

## 💰 Cost Analysis

### AWS Free Tier Eligible

This project is designed to run within AWS Free Tier limits:

| Resource | Free Tier | This Project | Cost |
|----------|-----------|--------------|------|
| **EC2 Instance** | 750 hours/month t2.micro | t3.medium (not free tier) | ~$30/month |
| **EBS Storage** | 30 GB | 20 GB GP3 | $0 (within limit) |
| **Data Transfer** | 100 GB out | Minimal | $0 (within limit) |
| **Elastic IP** | 1 free if attached | Not used | $0 |

**Note:** t3.medium is NOT free tier eligible. For free tier, change to t2.micro in `variables.tf`:
```hcl
variable "instance_type" {
  default = "t2.micro"  # Free tier eligible
}
```

**⚠️ Warning:** t2.micro may be too small for K3s + Argo CD + Application. Recommended minimum: t3.small

### Cost Optimization Tips

1. **Use t2.micro** for testing (free tier)
2. **Stop instance** when not in use (no compute charges)
3. **Delete resources** after testing with `terraform destroy`
4. **Use spot instances** for production (up to 90% savings)
5. **Monitor usage** with AWS Cost Explorer

---

## 🔒 Security Considerations

### Implemented Security Measures

1. **SSH Access Restriction**
   - Only your IP can SSH (configured via `your_ip` variable)
   - Uses SSH key authentication (no passwords)

2. **Secrets Management**
   - AWS credentials stored as Kubernetes secrets
   - Secrets not committed to Git (`.gitignore`)
   - Terraform variables marked as `sensitive`

3. **Network Security**
   - Security group with minimal required ports
   - Application runs in private container network
   - Only necessary ports exposed via NodePort

4. **IAM Best Practices**
   - Application uses separate IAM user
   - ReadOnly access for resource viewing
   - No admin credentials in application

### Security Recommendations

1. **Use IAM Roles** instead of access keys (for production)
   ```hcl
   # Attach IAM role to EC2 instance
   iam_instance_profile = aws_iam_instance_profile.app_profile.name
   ```

2. **Enable HTTPS** for Argo CD (production)
   - Use Let's Encrypt certificates
   - Configure Ingress with TLS

3. **Restrict Argo CD Access**
   - Change default admin password
   - Configure SSO (GitHub, Google, etc.)
   - Enable RBAC

4. **Regular Updates**
   ```bash
   # Update K3s
   curl -sfL https://get.k3
.io | sh -
   
   # Update system packages
   sudo apt-get update && sudo apt-get upgrade -y
   ```

5. **Network Segmentation**
   - Use private subnets for application
   - Place load balancer in public subnet
   - Restrict database access to application only

---

## 🧹 Cleanup

### Destroy All Resources

When you're done with the project, destroy all AWS resources to avoid charges:

```bash
terraform destroy
```

Type `yes` when prompted.

**This will delete:**
- EC2 instance
- Security group
- Key pair
- VPC components (if created)
- All data on the instance

**⚠️ Warning:** This action is irreversible. Make sure to backup any important data first.

### Verify Cleanup

```bash
# Check AWS Console to ensure all resources are deleted
# Or use AWS CLI:
aws ec2 describe-instances --filters "Name=tag:Project,Values=jb-project"
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=jb-project"
```

---

## 🎓 Learning Outcomes

This project demonstrates proficiency in the following areas:

### 1. Infrastructure as Code (IaC)
- ✅ Writing Terraform configurations
- ✅ Managing infrastructure state
- ✅ Using variables and outputs
- ✅ Templating with `templatefile()`
- ✅ Conditional resource creation

### 2. Cloud Computing (AWS)
- ✅ EC2 instance management
- ✅ VPC and networking concepts
- ✅ Security groups and firewall rules
- ✅ IAM and access management
- ✅ Cost optimization strategies

### 3. Kubernetes & Container Orchestration
- ✅ K3s lightweight Kubernetes
- ✅ Pod, Service, Deployment concepts
- ✅ Namespaces and resource isolation
- ✅ ConfigMaps and Secrets
- ✅ NodePort service exposure

### 4. GitOps & CI/CD
- ✅ Argo CD for continuous deployment
- ✅ Git as single source of truth
- ✅ Automated synchronization
- ✅ Self-healing applications
- ✅ Declarative configuration

### 5. DevOps Best Practices
- ✅ Automation and scripting
- ✅ Security best practices
- ✅ Monitoring and troubleshooting
- ✅ Documentation
- ✅ Version control

### 6. System Administration
- ✅ Linux system management
- ✅ Package installation
- ✅ Service configuration
- ✅ Log analysis
- ✅ SSH and remote access

---

## 📚 References

### Official Documentation
- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [K3s Documentation](https://docs.k3s.io/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

### Related Repositories
- [Infrastructure Repository](https://github.com/githuber20202/jb-terraform)
- [GitOps Repository](https://github.com/githuber20202/jb-gitops)
- [Docker Image](https://hub.docker.com/r/formy5000/resources_viewer)

### Learning Resources
- [Terraform Tutorial](https://learn.hashicorp.com/terraform)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [GitOps Principles](https://www.gitops.tech/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)

---

## 📝 Project Summary

This project successfully demonstrates:

1. **Complete Automation**: Single command deployment of entire infrastructure
2. **Modern DevOps Practices**: IaC, GitOps, containerization, orchestration
3. **Cloud-Native Architecture**: Kubernetes, microservices, declarative configuration
4. **Security Focus**: Secrets management, network isolation, access control
5. **Production-Ready**: Monitoring, logging, troubleshooting capabilities

**Total Deployment Time**: ~10-15 minutes  
**Lines of Code**: ~500 (Terraform + Shell scripts)  
**AWS Resources**: 8+ resources managed  
**Technologies**: 9+ tools integrated  

---

**Project Status**: ✅ Complete and Ready for Submission

**Author**: Alexander Yasheyev  
**Date**: January 2025  
**Institution**: JB College  
**Course**: CI/CD & DevOps  

---

*For questions or issues, please open an issue in the GitHub repository.*
