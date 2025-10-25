# Get latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Try to get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all VPCs as fallback
data "aws_vpcs" "all" {}

# Use default VPC if exists, otherwise create one
locals {
  use_default_vpc = try(data.aws_vpc.default.id, null) != null
  vpc_id          = local.use_default_vpc ? data.aws_vpc.default.id : aws_vpc.main[0].id
}

# Create VPC only if no default VPC exists
resource "aws_vpc" "main" {
  count = local.use_default_vpc ? 0 : 1

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-vpc"
    Project = var.project_name
  }
}

# Create Internet Gateway only if we created VPC
resource "aws_internet_gateway" "main" {
  count = local.use_default_vpc ? 0 : 1

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name    = "${var.project_name}-igw"
    Project = var.project_name
  }
}

# Create subnet only if we created VPC
resource "aws_subnet" "main" {
  count = local.use_default_vpc ? 0 : 1

  vpc_id                  = aws_vpc.main[0].id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-subnet"
    Project = var.project_name
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Create route table only if we created VPC
resource "aws_route_table" "main" {
  count = local.use_default_vpc ? 0 : 1

  vpc_id = aws_vpc.main[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = {
    Name    = "${var.project_name}-rt"
    Project = var.project_name
  }
}

# Associate route table with subnet
resource "aws_route_table_association" "main" {
  count = local.use_default_vpc ? 0 : 1

  subnet_id      = aws_subnet.main[0].id
  route_table_id = aws_route_table.main[0].id
}

# Get default subnet if using default VPC
data "aws_subnets" "default" {
  count = local.use_default_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create key pair
resource "aws_key_pair" "jb_key" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Security Group
resource "aws_security_group" "jb_sg" {
  name        = "${var.project_name}-sg"
  description = "Security group for JB project K3s cluster"
  vpc_id      = local.vpc_id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
    description = "SSH from your IP"
  }

  # K3s API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "K3s API"
  }

  # App NodePort
  ingress {
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application access"
  }

  # Argo CD UI
  ingress {
    from_port   = 30443
    to_port     = 30443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Argo CD UI"
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = {
    Name    = "${var.project_name}-sg"
    Project = var.project_name
  }
}

# EC2 Instance
resource "aws_instance" "k3s" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.jb_key.key_name

  # Use default subnet if exists, otherwise use created subnet
  subnet_id = local.use_default_vpc ? sort(data.aws_subnets.default[0].ids)[0] : aws_subnet.main[0].id

  vpc_security_group_ids = [aws_security_group.jb_sg.id]

  # Ensure public IP
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/user-data.sh", {
    gitops_repo  = var.gitops_repo
    docker_image = var.docker_image
  })

  tags = {
    Name    = "${var.project_name}-k3s"
    Project = var.project_name
  }
}