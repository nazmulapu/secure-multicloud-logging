variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "secure-logging"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for log collector"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "SSH key pair name for EC2 instance"
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 50
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this to your IP in production
}

variable "allowed_kibana_cidr" {
  description = "CIDR blocks allowed to access Kibana"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this to your IP in production
}
