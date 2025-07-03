terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.68.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Security Group for n8n server
resource "aws_security_group" "Amelia_n8n_sg" {
  name        = "Amelia_n8n-sg"
  description = "Allow SSH, HTTP, HTTPS, and n8n ports"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # n8n port
  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for PostgreSQL server
resource "aws_security_group" "db_sg" {
  name        = "n8n-db-sg"
  description = "Allow SSH and PostgreSQL access"

  # SSH for direct access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL access from n8n EC2
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.Amelia_n8n_sg.id]
  }

  # PostgreSQL access from anywhere (for testing; remove if you don't want this)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# PostgreSQL EC2 instance
resource "aws_instance" "postgres" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.db_sg.name]
  key_name        = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y postgresql

    sudo -u postgres psql -c "CREATE USER n8n WITH PASSWORD '${var.db_password}';"
    sudo -u postgres psql -c "CREATE DATABASE n8ndb OWNER n8n;"

    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf
    echo "host all all 0.0.0.0/0 md5" >> /etc/postgresql/*/main/pg_hba.conf

    systemctl restart postgresql
  EOF

  tags = {
    Name = "n8n-postgres"
  }
}

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
 feature/update-config
    chown -R 1000:1000 /data/n8n
    chmod -R 755 /data/n8n

 main

    docker run -d \
      --name n8n \
      --restart=always \
      -p 5678:5678 \
      -v /data/n8n:/home/node/.n8n \
 feature/update-config
      -e DB_TYPE=postgresdb \
      -e DB_POSTGRESDB_HOST=${aws_instance.postgres.private_ip} \
      -e DB_POSTGRESDB_PORT=5432 \
      -e DB_POSTGRESDB_DATABASE=n8ndb \
      -e DB_POSTGRESDB_USER=n8n \
      -e DB_POSTGRESDB_PASSWORD=${var.db_password} \

 main
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

# Elastic IP for n8n EC2
resource "aws_eip" "n8n_eip" {
  instance = aws_instance.n8n.id
}