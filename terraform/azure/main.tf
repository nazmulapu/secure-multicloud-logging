terraform {
  required_version = ">= 1.5.0"
  
  cloud {
    organization = "nazmulapu-labs"
    
    workspaces {
      name = "azure-log-generator"
    }
  }
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg"
  location = var.azure_region

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.project_name}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_cidr]
}

# Public IP
resource "azurerm_public_ip" "generator" {
  name                = "${var.project_name}-generator-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
  }
}

# Network Security Group
resource "azurerm_network_security_group" "generator" {
  name                = "${var.project_name}-generator-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # SSH inbound (restricted to your IP)
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ssh_cidr
    destination_address_prefix = "*"
  }

  # Rsyslog TLS outbound to AWS
  security_rule {
    name                       = "Rsyslog-TLS-Outbound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6514"
    source_address_prefix      = "*"
    destination_address_prefix = var.aws_collector_ip
  }

  tags = {
    Environment = var.environment
  }
}

# Network Interface
resource "azurerm_network_interface" "generator" {
  name                = "${var.project_name}-generator-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.generator.id
  }

  tags = {
    Environment = var.environment
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "generator" {
  network_interface_id      = azurerm_network_interface.generator.id
  network_security_group_id = azurerm_network_security_group.generator.id
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "generator" {
  name                = "${var.project_name}-generator"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.generator.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3 python3-pip
              EOF
  )

  tags = {
    Environment = var.environment
    Role        = "log-generator"
  }
}
