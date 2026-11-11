# ==============================================================================
# APPLICATION LOAD BALANCER PARA AS APLICACOES DO NODE GROUP "ng-senac-app"
# Listener 80 -> frontend estatico Nginx (NodePort 30080)
# Listener 8081 -> pessoas-service
# ==============================================================================

# Portas externas do ALB e NodePorts das aplicacoes
locals {
  app_alb_port      = 80
  pessoas_alb_port  = 8081
  pessoas_node_port = 30081
}

# Security Group do ALB: aceita HTTP publico nas portas das aplicacoes
resource "aws_security_group" "alb" {
  name        = "alb-senac-app-sg"
  description = "Permite acesso HTTP publico ao ALB das aplicacoes Senac"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "sg-alb-senac-app"
  }
}

# Entradas: HTTP publico nas portas 80 e 8081
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP publico"
  ip_protocol       = "tcp"
  from_port         = local.app_alb_port
  to_port           = local.app_alb_port
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_pessoas" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP publico - pessoas-service"
  ip_protocol       = "tcp"
  from_port         = local.pessoas_alb_port
  to_port           = local.pessoas_alb_port
  cidr_ipv4         = "0.0.0.0/0"
}

# Saidas: ALB encaminha trafego para as NodePorts dos nos
resource "aws_vpc_security_group_egress_rule" "alb_to_nodes" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Trafego do ALB para os nos EKS"
  ip_protocol                  = "tcp"
  from_port                    = var.app_node_port
  to_port                      = var.app_node_port
  referenced_security_group_id = module.eks.node_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "alb_to_nodes_pessoas" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Trafego do ALB para NodePort do pessoas-service"
  ip_protocol                  = "tcp"
  from_port                    = local.pessoas_node_port
  to_port                      = local.pessoas_node_port
  referenced_security_group_id = module.eks.node_security_group_id
}

# Nos EKS aceitam as NodePorts apenas vindas do ALB
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb" {
  security_group_id            = module.eks.node_security_group_id
  description                  = "NodePort da aplicacao vindo do ALB"
  ip_protocol                  = "tcp"
  from_port                    = var.app_node_port
  to_port                      = var.app_node_port
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb_pessoas" {
  security_group_id            = module.eks.node_security_group_id
  description                  = "NodePort do pessoas-service vindo do ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.pessoas_node_port
  to_port                      = local.pessoas_node_port
  referenced_security_group_id = aws_security_group.alb.id
}

# Load Balancer publico nas subnets publicas
resource "aws_lb" "app" {
  name               = "alb-senac-app"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "alb-senac-app"
  }
}

# Target Group do frontend estatico servido pelo Nginx
resource "aws_lb_target_group" "app" {
  name        = "tg-senac-app"
  port        = var.app_node_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = var.app_health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Target Group do pessoas-service
resource "aws_lb_target_group" "pessoas" {
  name        = "tg-senac-pessoas"
  port        = local.pessoas_node_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/healthz/ready/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Listener HTTP 80 encaminhando para o frontend estatico
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = local.app_alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Listener 8081 encaminhando para o Target Group do pessoas-service
resource "aws_lb_listener" "pessoas" {
  load_balancer_arn = aws_lb.app.arn
  port              = local.pessoas_alb_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pessoas.arn
  }
}

# Registra automaticamente as EC2 do node group nos Target Groups
resource "aws_autoscaling_attachment" "app_nodes" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["app_nodes"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.app.arn
}

resource "aws_autoscaling_attachment" "pessoas_nodes" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["app_nodes"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.pessoas.arn
}

# DNS publico do ALB
output "alb_dns_name" {
  description = "DNS publico do Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "alb_url" {
  description = "URL HTTP do frontend estatico via ALB"
  value       = "http://${aws_lb.app.dns_name}"
}

# URL pronta para o pessoas-service
output "alb_pessoas_url" {
  description = "URL HTTP do pessoas-service via ALB"
  value       = "http://${aws_lb.app.dns_name}:${local.pessoas_alb_port}"
}