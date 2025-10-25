#!/bin/bash
set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "========================================="
echo "Starting JB Project Setup"
echo "========================================="

# Update system
echo ">> Updating system..."
apt-get update
apt-get upgrade -y

# Install prerequisites
echo ">> Installing prerequisites..."
apt-get install -y curl git

# Install K3s
echo ">> Installing K3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Wait for K3s to be ready
echo ">> Waiting for K3s..."
sleep 60

# Set KUBECONFIG for all kubectl commands (after K3s is installed)
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Check K3s status
systemctl status k3s --no-pager

# Setup kubectl for ubuntu user
echo ">> Setting up kubectl..."
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Install kubectl
echo ">> Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install Helm
echo ">> Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Wait for K3s to be fully ready
echo ">> Waiting for K3s nodes..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Create AWS Credentials Secret (before ArgoCD sync)
echo ">> Creating AWS credentials Secret..."
cat <<SECRETEOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: default
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: "${aws_access_key_id}"
  AWS_SECRET_ACCESS_KEY: "${aws_secret_access_key}"
  AWS_DEFAULT_REGION: "${aws_app_region}"
SECRETEOF

# Create Argo CD namespace
echo ">> Creating Argo CD namespace..."
kubectl create namespace argocd

# Install Argo CD
echo ">> Installing Argo CD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
echo ">> Waiting for Argo CD pods..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=900s

# Patch Argo CD server to use NodePort
echo ">> Exposing Argo CD UI..."
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort", "ports": [{"port": 443, "targetPort": 8080, "nodePort": 30443, "name": "https"}]}}'

# Get Argo CD initial password
echo ">> Getting Argo CD password..."
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Argo CD Password: $ARGOCD_PASSWORD" > /home/ubuntu/argocd-password.txt
chown ubuntu:ubuntu /home/ubuntu/argocd-password.txt

# Create Argo CD Application
echo ">> Creating Argo CD Application..."
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aws-resources-viewer
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${gitops_repo}
    targetRevision: main
    path: aws-resources-viewer
    helm:
      releaseName: aws-resources-viewer
      valueFiles:
        - values.yaml 
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Wait a bit for first sync
echo ">> Waiting for Argo CD to sync..."
sleep 60

# Get instance info
INSTANCE_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

# Create info file
cat <<EOF > /home/ubuntu/cluster-info.txt
========================================
JB Project K3s Cluster Info
========================================

Instance IP: $INSTANCE_IP

Application:
  URL: http://$INSTANCE_IP:30080
  
Argo CD UI:
  URL: https://$INSTANCE_IP:30443
  Username: admin
  Password: $ARGOCD_PASSWORD
  
kubectl:
  Config: /home/ubuntu/.kube/config
  
Useful commands:
  kubectl get nodes
  kubectl get pods -A
  kubectl get app -n argocd
  
GitOps Repo: ${gitops_repo}
Docker Image: ${docker_image}

========================================
EOF

chown ubuntu:ubuntu /home/ubuntu/cluster-info.txt

echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo "App URL: http://$INSTANCE_IP:30080"
echo "Argo CD: https://$INSTANCE_IP:30443"
echo "Password saved to: /home/ubuntu/argocd-password.txt"
