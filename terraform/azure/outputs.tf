output "generator_public_ip" {
  description = "Public IP of the log generator VM"
  value       = azurerm_public_ip.generator.ip_address
}

output "generator_vm_name" {
  description = "Name of the log generator VM"
  value       = azurerm_linux_virtual_machine.generator.name
}

output "generator_private_ip" {
  description = "Private IP of the log generator VM"
  value       = azurerm_network_interface.generator.private_ip_address
}

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "ssh_command" {
  description = "SSH command to connect to the generator"
  value       = "ssh -i ~/.ssh/id_rsa ${var.admin_username}@${azurerm_public_ip.generator.ip_address}"
}
