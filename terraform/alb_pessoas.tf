# ==============================================================================
# SEGUNDA APLICACAO (pessoas-service) NO MESMO ALB
# Listener 8081 -> Target Group tg-senac-pessoas -> NodePort 30081
# ==============================================================================

# Porta externa do ALB e NodePort da segunda aplicacao
locals {
  pessoas_alb_port  = 8081
  pessoas_node_port = 30081
}

# Entrada: HTTP na porta 8081 vindo de qualquer origem
resource "aws_vpc_security_group_ingress_rule" "alb_pessoas" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP publico - pessoas-service"
  ip_protocol       = "tcp"
  from_port         = local.pessoas_alb_port
  to_port           = local.pessoas_alb_port
  cidr_ipv4         = "0.0.0.0/0"
}

# Saida: ALB fala com a NodePort 30081 dos nos
resource "aws_vpc_security_group_egress_rule" "alb_to_nodes_pessoas" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Trafego do ALB para NodePort do pessoas-service"
  ip_protocol                  = "tcp"
  from_port                    = local.pessoas_node_port
  to_port                      = local.pessoas_node_port
  referenced_security_group_id = module.eks.node_security_group_id
}

# Nos EKS aceitam a NodePort 30081 apenas vinda do ALB
resource "aws_vpc_security_group_ingress_rule" "nodes_from_alb_pessoas" {
  security_group_id            = module.eks.node_security_group_id
  description                  = "NodePort do pessoas-service vindo do ALB"
  ip_protocol                  = "tcp"
  from_port                    = local.pessoas_node_port
  to_port                      = local.pessoas_node_port
  referenced_security_group_id = aws_security_group.alb.id
}

# Target Group da segunda aplicacao
resource "aws_lb_target_group" "pessoas" {
  name        = "tg-senac-pessoas"
  port        = local.pessoas_node_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/actuator/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
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

# Registra automaticamente as EC2 do mesmo ASG neste Target Group
resource "aws_autoscaling_attachment" "pessoas_nodes" {
  autoscaling_group_name = module.eks.eks_managed_node_groups["app_nodes"].node_group_autoscaling_group_names[0]
  lb_target_group_arn    = aws_lb_target_group.pessoas.arn
}

# URL pronta para o segundo app
output "alb_pessoas_url" {
  description = "URL HTTP do pessoas-service via ALB"
  value       = "http://${aws_lb.app.dns_name}:${local.pessoas_alb_port}"
}