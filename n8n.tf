# n8n EC2 instance
resource "aws_instance" "n8n" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.Amelia_n8n_sg.name]
  key_name        = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y docker.io docker-compose
    systemctl start docker
    systemctl enable docker

    mkdir -p /data/n8n
    chown -R 1000:1000 /data/n8n
    chmod -R 755 /data/n8n

    docker run -d \
      --name n8n \
      --restart=always \
      -p 5678:5678 \
      -v /data/n8n:/home/node/.n8n \
      -e DB_TYPE=postgresdb \
      -e DB_POSTGRESDB_HOST=${aws_instance.postgres.private_ip} \
      -e DB_POSTGRESDB_PORT=5432 \
      -e DB_POSTGRESDB_DATABASE=n8ndb \
      -e DB_POSTGRESDB_USER=n8n \
      -e DB_POSTGRESDB_PASSWORD=${var.db_password} \
      -e N8N_BASIC_AUTH_ACTIVE=true \
      -e N8N_SECURE_COOKIE=false \
      -e N8N_BASIC_AUTH_USER=${var.n8n_user} \
      -e N8N_BASIC_AUTH_PASSWORD=${var.n8n_password} \
      n8nio/n8n
  EOF

  tags = {
    Name = "n8n-server"
  }
}