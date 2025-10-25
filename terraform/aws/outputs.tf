output "collector_elastic_ip" {
  description = "Elastic IP of the log collector instance"
  value       = aws_eip.collector.public_ip
}

output "collector_instance_id" {
  description = "Instance ID of the log collector"
  value       = aws_instance.collector.id
}

output "collector_private_ip" {
  description = "Private IP of the log collector instance"
  value       = aws_instance.collector.private_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "Security Group ID for the collector"
  value       = aws_security_group.collector.id
}

output "ssh_command" {
  description = "SSH command to connect to the collector"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.collector.public_ip}"
}
