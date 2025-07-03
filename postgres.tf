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