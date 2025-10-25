# JB Project - Terraform Infrastructure

This repository contains Terraform configuration for deploying K3s cluster with Argo CD on AWS.

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- SSH key pair (~/.ssh/id_rsa)

## Architecture
```
EC2 (t2.micro - Free Tier)
├── K3s (Kubernetes)
├── Argo CD
└── AWS Resources Viewer App
```

## Usage

### 1. Initialize Terraform
```bash
terraform init
```

### 2. Plan (preview changes)
```bash
terraform plan
```

When prompted, enter your public IP (e.g., `82.166.123.45/32`)

### 3. Apply (create resources)
```bash
terraform apply
```

Confirm with `yes`

### 4. Wait ~10 minutes

The user-data script will:
- Install K3s
- Install Argo CD
- Deploy the application

### 5. Access

After deployment:

**Application:**
```
http://<EC2_IP>:30080
```

**Argo CD UI:**
```
https://<EC2_IP>:30443
Username: admin
Password: SSH to instance and run:
         cat /home/ubuntu/argocd-password.txt
```

**SSH:**
```bash
ssh -i ~/.ssh/id_rsa ubuntu@<EC2_IP>
```

## Outputs

After `terraform apply`, you'll see:
- `instance_public_ip` - EC2 public IP
- `app_url` - Application URL
- `argocd_url` - Argo CD UI URL
- `ssh_command` - SSH connection command

## Monitoring Setup Progress

SSH to the instance and monitor:
```bash
tail -f /var/log/user-data.log
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Cost

**Free Tier eligible:**
- EC2 t2.micro: 750 hours/month
- EBS 20GB: within 30GB limit
- Data transfer: within limits

**Total: $0** (if within Free Tier)

## Files

- `provider.tf` - AWS provider configuration
- `variables.tf` - Input variables
- `main.tf` - Main infrastructure
- `user-data.sh` - Bootstrap script
- `outputs.tf` - Output values

## Variables

| Name | Description | Default | Required |
|------|-------------|---------|----------|
| aws_region | AWS region for Terraform | us-east-1 | No |
| instance_type | EC2 instance type | t2.small | No |
| project_name | Project name for tagging | jb-project | No |
| your_ip | Your IP for SSH access | - | Yes |
| gitops_repo | GitOps repository URL | github.com/githuber20202/jb-gitops.git | No |
| docker_image | Docker image | formy5000/resources_viewer | No |
| **aws_access_key_id** | **AWS Access Key for app** | - | **Yes** |
| **aws_secret_access_key** | **AWS Secret Key for app** | - | **Yes** |
| **aws_app_region** | **AWS region for app to query** | us-east-1 | No |

### AWS Credentials Configuration

The application requires AWS credentials to query AWS resources. These credentials are:
- Stored as a Kubernetes Secret (not in Git!)
- Created automatically during EC2 bootstrap
- Used by the application Pod to access AWS APIs

**Important:** Add these to `terraform.tfvars`:
```hcl
aws_access_key_id     = "AKIAIOSFODNN7EXAMPLE"
aws_secret_access_key = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
aws_app_region        = "us-east-1"
```

**Note:** `terraform.tfvars` is in `.gitignore` - your credentials won't be committed to Git.

## Security

- SSH access restricted to your IP only
- Application exposed on NodePort 30080
- Argo CD UI on NodePort 30443

## Troubleshooting

**Can't SSH:**
- Check your IP hasn't changed
- Update security group manually if needed

**App not loading:**
- Wait 10 minutes for full setup
- Check logs: `tail -f /var/log/user-data.log`
- Check pods: `kubectl get pods -A`

**Argo CD not syncing:**
- Check application: `kubectl get app -n argocd`
- Check Argo CD logs: `kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server`

## Author

Alexander Yasheyev, JB College Student
