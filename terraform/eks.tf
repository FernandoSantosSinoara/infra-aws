# ==============================================================================
# CLUSTER KUBERNETES GERENCIADO (AMAZON EKS)
# ==============================================================================
# Módulo oficial e homologado para criação e sustentação do cluster EKS
module "eks" {
  # Origem do módulo no Terraform Registry oficial
  source = "terraform-aws-modules/eks/aws"
  # Versão recomendada do módulo EKS v20
  version = "~> 20.8"

  # Nome do cluster referenciando a variável padrão
  cluster_name = var.cluster_name
  # Versão estável do Kubernetes na AWS (v1.31)
  cluster_version = "1.31"

  # Permite que o endpoint de API do Kubernetes seja alcançado com segurança pela internet
  cluster_endpoint_public_access = true

  # Desativa a criação automática de provedor OIDC para IRSA (útil quando restrito por SCPs organizacionais)
  enable_irsa = false

  # ID da VPC onde os nós de computação e redes do Kubernetes serão inseridos
  vpc_id = module.vpc.vpc_id
  # Subnets privadas onde as máquinas virtuais EC2 dos nós de trabalho residirão
  subnet_ids = module.vpc.private_subnets

  # Habilita o modo moderno de autenticação baseado em API Entries e ConfigMap legada
  authentication_mode = "API_AND_CONFIG_MAP"

  # Definição do grupo de nós gerenciados (Managed Node Group)
  eks_managed_node_groups = {
    # Identificador do grupo de nós que rodarão as aplicações de negócio
    app_nodes = {
      # Nome do Node Group no console da AWS
      name = "ng-senac-app"
      # Família de instância EC2 balanceada (2 vCPUs e 2GB RAM - custo eficiente para estudos)
      instance_types = ["t3.small"]

      # Quantidade mínima de servidores EC2 mantidos ativos pelo Auto Scaling
      min_size = 1
      # Quantidade máxima de servidores EC2 permitidos em caso de aumento de carga
      max_size = 3
      # Quantidade desejada de servidores em operação normal
      desired_size = 1

      # Tipo de compra da capacidade: Instâncias sob demanda com garantia de disponibilidade
      capacity_type = "ON_DEMAND"
    }
  }

  # Configuração de permissões de acesso ao cluster Kubernetes via AWS IAM
  access_entries = {
    # Entrada 1: Concede acesso total ao usuário de terminal local do instrutor/aluno
    admin_user = {
      # [id-conta] ARN do usuário IAM criado na conta AWS para gerenciamento via CLI local
      principal_arn = "arn:aws:iam::188785237347:user/admin-cli"
      # Lista de políticas de acesso ao cluster atribuídas ao usuário
      policy_associations = {
        # Associação com a política de Super Administrador do Cluster
        admin = {
          # ARN padrão da AWS que concede autorização máxima em todos os namespaces do Kubernetes
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          # Escopo da permissão abrangendo todo o cluster
          access_scope = {
            type = "cluster"
          }
        }
      }
    }

    # Entrada 2: Concede acesso de Administrador para a Role do GitHub Actions rodar deploys
    github_actions = {
      # [id-conta] ARN da IAM Role assumida pelo runner do GitHub Actions via OIDC
      principal_arn = "arn:aws:iam::188785237347:role/GitHubActions-Terraform-Role"
      # Lista de políticas de acesso atribuídas ao pipeline de automação
      policy_associations = {
        # Associação com a política administrativa do cluster
        admin = {
          # Permite que o pipeline execute 'kubectl apply' e gerencie pods, services e deployments
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          # Escopo total do cluster
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
}