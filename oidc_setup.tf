# 1. Crear el Identity Provider OIDC para GitHub
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  
  # Huella digital (Thumbprint) del certificado raíz de GitHub
  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"] 
}

# 2. Crear el Rol de IAM que asumirá el pipeline de GitHub Actions
resource "aws_iam_role" "github_actions_terraform" {
  name = "github-actions-terraform-role"

  # Relación de confianza (Trust Policy) restringida a tu repositorio
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # Reemplaza con tu organización/usuario y nombre exacto del repositorio
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
          StringLike = {
            # Permite la ejecución solo desde la rama main de tu repositorio específico
            "token.actions.githubusercontent.com:sub": "repo:TU_ORGANIZACION_O_USUARIO/TU_REPOSITORIO:ref:refs/heads/main"
          }
        }
      }
    ]
  })
}

# 3. Adjuntar políticas al Rol (Ejemplo con AdministratorAccess)
# NOTA: En producción se recomienda usar el principio de menor privilegio.
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output para copiar el ARN del rol generado
output "role_arn" {
  value       = aws_iam_role.github_actions_terraform.arn
  description = "Copia este ARN para tu archivo de GitHub Actions"
}
