variable "azure_region" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"  # Amsterdam, Netherlands
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

variable "vnet_cidr" {
  description = "CIDR block for VNet"
  type        = string
  default     = "10.1.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.1.1.0/24"
}

variable "vm_size" {
  description = "Azure VM size for log generator"
  type        = string
  default     = "Standard_B1ms"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key content for VM access"
  type        = string
  sensitive   = true
}

variable "os_disk_size" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "aws_collector_ip" {
  description = "AWS collector Elastic IP (for NSG rule)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the generator VM"
  type        = list(string)
  default     = []
}
