# ==============================================================================
# MÓDULO DE REDE (AMAZON VPC)
# ==============================================================================
# Utiliza o módulo padrão e homologado da comunidade oficial para criação de redes seguras na AWS
module "vpc" {
  # Origem do módulo no Terraform Registry oficial
  source = "terraform-aws-modules/vpc/aws"
  # Versão estável do módulo de VPC
  version = "~> 5.5"

  # Nome atribuído à Virtual Private Cloud (VPC)
  name = "vpc-senac-aws"
  # Bloco de endereçamento IPv4 privado principal (permite até 65.536 endereços IPs internos)
  cidr = "10.0.0.0/16"

  # Lista de Zonas de Disponibilidade (AZs) distribuídas geograficamente para garantir Alta Disponibilidade
  azs = ["us-east-2a", "us-east-2b"]
  # Subnets privadas: Onde os nós do Kubernetes e bancos de dados ficam protegidos sem IP público
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  # Subnets públicas: Onde gateways e componentes com acesso direto à internet residem
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"]

  # Habilita NAT Gateway para que os nós nas subnets privadas possam baixar imagens Docker e pacotes da internet
  enable_nat_gateway = true
  # Cria apenas 1 NAT Gateway compartilhado para economizar custos de laboratório didático
  single_nat_gateway = true
  # Habilita resolução de nomes DNS internos na VPC
  enable_dns_hostnames = true
  # Habilita suporte a consultas de DNS nativas na VPC
  enable_dns_support = true

  # Tags mandatórias para que a AWS e os Load Balancers públicos descubram onde criar recursos
  public_subnet_tags = {
    # Sinaliza para a AWS que Load Balancers públicos da internet podem ser vinculados aqui
    "kubernetes.io/role/elb" = 1
    # Associa a subnet ao ciclo de vida do cluster Kubernetes
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }

  # Tags mandatórias para criação de Load Balancers internos e privados
  private_subnet_tags = {
    # Sinaliza para o Kubernetes que Load Balancers internos e VPC Links devem utilizar estas subnets
    "kubernetes.io/role/internal-elb" = 1
    # Associa a subnet ao ciclo de vida do cluster Kubernetes
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
  }
}