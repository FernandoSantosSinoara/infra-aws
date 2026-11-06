# ==============================================================================
# CONFIGURAÇÃO GERAL E BACKEND DO TERRAFORM
# ==============================================================================
# Bloco central de configuração de ferramentas e requisitos mínimos do Terraform
terraform {
  # Exige que o binário instalado na máquina execute versão 1.10.0 ou superior
  required_version = ">= 1.10.0"

  # Declaração dos provedores externos gerenciados pela HashiCorp necessários para o projeto
  required_providers {
    # Provedor da AWS para gerenciar instâncias, VPCs, EKS, API Gateway, etc.
    aws = {
      # Endereço oficial no Terraform Registry
      source = "hashicorp/aws"
      # Permite atualizações compatíveis dentro da versão principal 5.x (a partir de 5.40)
      version = "~> 5.40"
    }
    # Provedor utilitário Archive para compactar arquivos zip localmente durante o plan/apply
    archive = {
      # Endereço oficial no Terraform Registry
      source = "hashicorp/archive"
      # Versão estável do utilitário de compressão de arquivos
      version = "~> 2.4"
    }
  }

  # Configuração de armazenamento remoto do arquivo de estado (terraform.tfstate)
  # O Backend remoto garante que o time compartilhe o mesmo estado sem sobrescrever alterações
  backend "s3" {
    # [id-conta] Nome do bucket S3 criado previamente na AWS para persistência do estado
    bucket = "tfstate-senac-aws-188785237347"
    # Caminho/chave dentro do bucket onde o arquivo .tfstate ficará guardado
    key = "infra/terraform.tfstate"
    # Região onde o bucket S3 de estado foi provisionado
    region = "us-east-2"
    # Habilita criptografia em repouso dos dados do estado (Server-Side Encryption)
    encrypt = true
    # Habilita mecanismo nativo de trava (lock) para evitar execuções simultâneas concorrentes
    use_lockfile = true
  }
}

# Configura o provedor AWS com as propriedades globais da conta
provider "aws" {
  # Define a região geográfica padrão a partir da variável declarada
  region = var.aws_region

  # Tags padrão que serão injetadas automaticamente em ABSOLUTAMENTE TODOS os recursos criados
  default_tags {
    tags = {
      # Identificador do projeto de treinamento/laboratório
      Project = "App-Senac-AWS"
      # Ambiente de execução da aplicação
      Environment = "Production"
      # Ferramenta responsável pelo gerenciamento da infraestrutura como código
      ManagedBy = "Terraform"
    }
  }
}