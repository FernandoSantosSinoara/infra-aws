# ==============================================================================
# DECLARAÇÃO DE VARIÁVEIS DO TERRAFORM
# ==============================================================================
# Define a região padrão da AWS onde toda a infraestrutura física/lógica será criada
variable "aws_region" {
  # Tipo primitivo string
  type = string
  # Região padrão: Ohio (us-east-2), escolha com excelente custo/benefício e disponibilidade
  default = "us-east-2"
  # Descrição explicativa do propósito da variável
  description = "Região da AWS onde os recursos serão provisionados (ex: us-east-2 Ohio)"
}

# Define o nome único atribuído ao Cluster EKS (Kubernetes gerenciado da AWS)
variable "cluster_name" {
  # Tipo primitivo string
  type = string
  # Nome base do cluster Kubernetes
  default = "cluster-app-senac-aws"
  # Descrição informativa para os administradores de infraestrutura
  description = "Nome do Cluster Amazon EKS"
}

# NodePort do frontend Nginx exposto nos nós EC2 e usado como destino do ALB
variable "app_node_port" {
  type        = number
  default     = 30080
  description = "NodePort (30000-32767) do Service Kubernetes do frontend Nginx, alvo do ALB"
}

# Caminho usado pelo health check do Target Group
variable "app_health_check_path" {
  type        = string
  default     = "/"
  description = "Caminho HTTP verificado pelo ALB para validar o frontend Nginx"
}

# Identificador da instância RDS
variable "db_identifier" {
  type        = string
  default     = "mysql-senac-aws"
  description = "Identificador da instância RDS MySQL"
}

# Nome do banco criado inicialmente
variable "db_name" {
  type        = string
  default     = "appdb"
  description = "Nome do banco de dados inicial"
}

# Usuário administrador do banco
variable "db_username" {
  type        = string
  default     = "admin"
  description = "Usuário administrador do MySQL (a senha é gerenciada pelo Secrets Manager)"
}

# Classe da instância
variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
  description = "Classe da instância RDS"
}

# Armazenamento em GB
variable "db_allocated_storage" {
  type        = number
  default     = 20
  description = "Armazenamento do RDS em GB"
}