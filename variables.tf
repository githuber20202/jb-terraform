variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"  # Free tier!
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "jb-project"
}

variable "your_ip" {
  description = "Your IP for SSH access (x.x.x.x/32)"
  type        = string
  # Will prompt during apply
}

variable "gitops_repo" {
  description = "GitOps repository URL"
  type        = string
  default     = "https://github.com/githuber20202/jb-gitops.git"
}

variable "docker_image" {
  description = "Docker image"
  type        = string
  default     = "formy5000/resources_viewer"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for the application"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for the application"
  type        = string
  sensitive   = true
  default     = ""
}

variable "aws_app_region" {
  description = "AWS Region for the application to query resources"
  type        = string
  default     = "us-east-1"
}
