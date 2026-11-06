# ==============================================================================
# REPOSITÓRIO DE IMAGENS DE CONTAINER (AMAZON ECR)
# ==============================================================================
# Provisiona um repositório Docker privado totalmente gerenciado pela AWS
resource "aws_ecr_repository" "app_repo" {
  # Nome do repositório onde as imagens da aplicação Spring Boot serão versionadas
  name = "hello-aws-service"
  # Permite que uma mesma tag (como 'latest') seja sobrescrita por novos builds de pipeline
  image_tag_mutability = "MUTABLE"

  # Configuração de auditoria e segurança do repositório
  image_scanning_configuration {
    # Executa varredura automática de vulnerabilidades conhecidas (CVE) a cada push de imagem
    scan_on_push = true
  }
}

# Saída que exibe a URL completa necessária para comandos de login, build e push do Docker
output "ecr_repository_url" {
  # Valor retornado dinamicamente pelo recurso provisionado
  value = aws_ecr_repository.app_repo.repository_url
  # Descrição informativa do dado retornado
  description = "URL pública do repositório no Amazon Elastic Container Registry"
}