variable "aws_region" {
  description = "AWS region for deploying resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
  default     = "secure-logging"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the log collector"
  type        = string
  default     = "m7i-flex.large"  # Free Tier eligible in select regions (2 vCPU, 8GB RAM). Excellent for ELK stack
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 50
}

variable "ssh_public_key" {
  description = "SSH public key content for EC2 access (content of ~/.ssh/id_rsa.pub)"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "List of CIDR blocks allowed to SSH into the collector"
  type        = list(string)
}

variable "allowed_kibana_cidr" {
  description = "List of CIDR blocks allowed to access Kibana dashboard"
  type        = list(string)
}
