output "n8n_elastic_ip" {
  description = "Elastic IP of the n8n EC2 instance"
  value       = aws_eip.n8n_eip.public_ip
}

output "n8n_url" {
  description = "URL to access n8n over HTTP"
  value       = "http://${aws_eip.n8n_eip.public_ip}:5678"
}

output "n8n_private_ip" {
  description = "Private IP of the n8n EC2 instance"
  value       = aws_instance.n8n.private_ip
}

output "postgres_public_ip" {
  description = "Public IP of the PostgreSQL EC2 instance"
  value       = aws_instance.postgres.public_ip
}

output "postgres_private_ip" {
  description = "Private IP of the PostgreSQL EC2 instance"
  value       = aws_instance.postgres.private_ip
}