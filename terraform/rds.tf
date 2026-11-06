# ==============================================================================
# BANCO DE DADOS RELACIONAL (AMAZON RDS - MYSQL)
# ==============================================================================
# Agrupa as subnets privadas da VPC onde o RDS pode ser colocado (mínimo 2 AZs)
resource "aws_db_subnet_group" "mysql" {
  # Nome do subnet group no console da AWS
  name = "db-subnet-senac-aws"
  # Subnets privadas: o banco nunca recebe IP público
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "db-subnet-senac-aws"
  }
}

# Firewall do banco: libera a porta 3306 apenas para os nós do EKS
resource "aws_security_group" "rds" {
  # Nome do security group
  name = "rds-mysql-senac-sg"
  # Descrição do propósito
  description = "Permite acesso MySQL somente a partir dos nos do EKS"
  # VPC onde o security group será criado
  vpc_id = module.vpc.vpc_id

  # Entrada: MySQL (3306) somente a partir do security group dos nós do EKS
  ingress {
    description     = "MySQL a partir dos nos do EKS"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  tags = {
    Name = "rds-mysql-senac-sg"
  }
}

# Instância RDS MySQL
resource "aws_db_instance" "mysql" {
  # Identificador único da instância
  identifier = var.db_identifier

  # Engine e versão do MySQL
  engine         = "mysql"
  engine_version = "8.0"
  # Classe de instância econômica para laboratório
  instance_class = var.db_instance_class

  # Armazenamento SSD de uso geral
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # Banco inicial e usuário administrador
  db_name  = var.db_name
  username = var.db_username
  # Senha gerada pela AWS e guardada no Secrets Manager (não fica no código)
  manage_master_user_password = true

  # Rede: subnets privadas, sem acesso público e protegido pelo security group
  db_subnet_group_name   = aws_db_subnet_group.mysql.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  # Sem Multi-AZ para reduzir custo no laboratório
  multi_az = false

  # Laboratório: sem backup e sem snapshot final para facilitar o destroy
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
  apply_immediately       = true

  tags = {
    Name = var.db_identifier
  }
}

# Endpoint (DNS) do banco, usado na URL JDBC da aplicação
output "rds_endpoint" {
  description = "Endpoint do RDS MySQL"
  value       = aws_db_instance.mysql.address
}

# ARN do secret no Secrets Manager com a senha do usuário administrador
output "rds_secret_arn" {
  description = "ARN do secret com as credenciais do RDS"
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}