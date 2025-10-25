output "collector_public_ip" {
  description = "Public IP address of the log collector (Elastic IP)"
  value       = aws_eip.collector.public_ip
}

output "collector_instance_id" {
  description = "EC2 instance ID of the log collector"
  value       = aws_instance.collector.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "security_group_id" {
  description = "Security group ID for the collector"
  value       = aws_security_group.collector.id
}

output "ssh_command" {
  description = "SSH command to connect to the collector"
  value       = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_eip.collector.public_ip}"
}

output "kibana_url" {
  description = "Kibana dashboard URL"
  value       = "http://${aws_eip.collector.public_ip}:5601"
}

output "key_pair_name" {
  description = "Name of the SSH key pair created in AWS"
  value       = aws_key_pair.collector.key_name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key on your local machine"
  value       = "~/.ssh/id_rsa (or the key you used for ssh_public_key variable)"
}
