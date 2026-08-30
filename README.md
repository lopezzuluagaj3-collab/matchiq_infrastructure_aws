# Terraform AWS Cluster Practice

Infraestructura como Código (IaC) para el despliegue de un entorno productivo en AWS, compuesto por múltiples servicios de aplicación, cómputo, mensajería y almacenamiento, totalmente modularizado y versionado con Terraform.

## Descripción general

Este proyecto provisiona un entorno AWS aislado y seguro para ejecutar una arquitectura multi-servicio en capas. El stack incluye un punto de entrada público, servicios de aplicación en subred privada y una base de datos relacional. Toda la infraestructura se despliega como código reproducible, con políticas de seguridad aplicadas por defecto, escaneo automatizado de cumplimiento y pipeline CI/CD para validación automática de cambios.

## Arquitectura

```
Internet
   |
   |  HTTP / HTTPS / SSH (desde IP autorizada)
   v
[ Internet Gateway ]
   |
   |  Subred Pública (10.0.1.0/24)
   |
[ Proxy / Bastion — EC2 t3.small ]
   |  Elastic IP estática
   |  Acceso exclusivo desde SG de administración
   v
[ NAT Gateway ]
   |
   |  Subred Privada (10.0.2.0/24)
   |
   |-- [ App Server 1 — EC2 m7i-flex.large ]
   |-- [ App Server 2 / Workers — EC2 c7i-flex.large ]
   |-- [ Backend / API + RabbitMQ — EC2 c7i-flex.large ]
   |-- [ Base de Datos — EC2 t3.micro ]
```

- **Zona pública:** solo el proxy/bastion tiene acceso directo desde internet.
- **Zona privada:** todos los servicios de aplicación y datos. Sin IPs públicas.
- **Conectividad:** tráfico entre servicios exclusivamente por referencias de Security Groups.
- **Modelo:** una instancia EC2 dedicada por servicio, aislando responsabilidades y permitiendo escalado independiente.

## Componentes

| Componente | Recurso AWS | Descripción |
|---|---|---|
| Red | VPC, Subredes, IGW, NAT GW | Aislamiento público/privado, enrutamiento controlado |
| Seguridad | Security Groups | Acceso por SG references, sin CIDR abiertos innecesarios |
| Cómputo | EC2 | Proxy (t3.small), Backend (c7i-flex.large), Workers (c7i-flex.large), DB (t3.micro) |

| Estado | S3 Backend | `terraform.tfstate` remoto encriptado, sin locking DinamoDB (MVP) |

## Características de seguridad

- **IMDSv2 forzado:** `http_tokens = "required"` en todas las instancias EC2.
- **Acceso SSH restringido:** solo desde IP/CIDR administrativo definido en variable.
- **Comunicación service-to-service:** exclusivamente por ID de Security Group, sin rangos CIDR amplios.
- **Escaneo estático:** integrado con **Checkov** para validación de políticas CIS/PCI en cada cambio.
- **Cifrado:** volúmenes EBS encriptados (`gp3`), backend S3 encriptado.

## CI/CD

Uno de los aspectos más destacados del proyecto es la integración continua y despliegue automatizado:

- **Pipeline de validación:** cada cambio en el código dispara automáticamente `terraform plan` y escaneo con **Checkov** antes de cualquier aplicación.
- **Control de calidad:** la pipeline valida sintaxis, políticas de seguridad y posibles recursos destruidos/recreados sin revisión.
- **Seguridad por defecto:** la combinación de `terraform plan` + Checkov asegura que ningún cambio llegue a producción sin pasar por revisiones automáticas de cumplimiento.
- **Trazabilidad:** cada ejecución deja registro de los cambios aplicados y su estado de seguridad.

## Prerrequisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.7.0`
- [AWS CLI](https://aws.amazon.com/cli/) configurado con credenciales válidas
- Permisos IAM para gestionar VPC, EC2, S3, IAM y Security Groups
- Key pairs existentes en AWS para acceso SSH (`KEY_PROXY`, `KEY_GENERAL`)

## Estructura del proyecto

```
.
├── main.tf                  # Módulo raíz: providers, data sources y composición
├── variables.tf             # Variables globales (región, ambiente, keys)
├── outputs.tf               # Salidas útiles (IPs, IDs)
├── locals.tf                # Tags y prefijos comunes
├── versions.tf              # Versionado de providers y backend remoto
├── terraform.tfvars         # Valores específicos del entorno (no versionado)
├── oidc_setup.tf            # Configuración OIDC (si aplica)
├── checkov-report.json      # Reporte de escaneo de seguridad
└── modules/
    ├── networking/           # VPC, subredes, tablas de rutas, gateways
    ├── security_groups/      # Definición de SGs por servicio
    ├── compute/              # Instancias EC2, EIP, discos

```

## Uso

### 1. Clonar el repositorio

```bash
git clone <repository-url>
cd matchiq_infrastructure_aws
```

### 2. Configurar variables

Crear `terraform.tfvars` en la raíz:

```hcl
aws_region       = "us-east-1"
environment      = "dev"
owner            = "matchiq"
allowed_ssh_cidr = "203.0.113.0/32"

KEY_PROXY   = "mi-key-proxy"
KEY_GENERAL = "mi-key-general"
```

> `terraform.tfvars` está ignorado en `.gitignore` porque puede contener valores sensores o específicos del entorno.

### 3. Inicializar Terraform

```bash
terraform init
```

### 4. Revisar el plan

```bash
terraform plan
```

Verificar que no haya recursos marcados con `-/+` en producción sin revisión explícita.

### 5. Aplicar

```bash
terraform apply
```

Confirmar con `yes` cuando el plan coincida con lo esperado.

## Gestión de estado

El proyecto utiliza **backend remoto en S3** encriptado para `terraform.tfstate`.

**Limitación actual:** no cuenta con tabla DynamoDB para locking. Esto significa que, en esta etapa MVP, se recomienda aplicar cambios desde un único operador o canal controlado para evitar condiciones de carrera en el estado.

## Escaneo de seguridad

Ejecutar Checkov antes de aplicar cambios:

```bash
checkov -d .
```

El reporte generado incluye validaciones contra políticas CIS para AWS, incluyendo:
- IMDSv2 requerido en instancias EC2
- Security Groups aplicados a recursos
- Cifrado de volúmenes y buckets S3
- Logging de VPC

## Pipeline CI/CD

El repositorio incluye un flujo de integración continua y despliegue automatizado mediante GitHub Actions que valida automáticamente cada cambio antes de aplicarlo en AWS.

### Flujo automático

1. **Push a `main`** — se dispara la pipeline automáticamente.
2. **Validación de código** — ejecuta `terraform init`, `terraform plan` y escaneo con **Checkov**.
3. **Análisis de calidad** — ejecuta **SonarQube Scanner** sobre los archivos `.tf`.
4. **Notificaciones** — envía alertas por correo electrónico con el estado de la pipeline.
5. **Apply automatizado** — si todas las validaciones pasan, aplica los cambios en AWS.

### Secrets requeridos

Para que la pipeline funcione es necesario configurar los siguientes secrets en el repositorio de GitHub:

| Secret | Descripción |
|---|---|
| `AWS_REGION` | Región de AWS donde se despliega la infraestructura (ej: `us-east-1`). |
| `AWS_ROLE_ARN` | ARN del rol IAM creado para que GitHub Actions asuma permisos en AWS mediante OIDC. |
| `SONAR_TOKEN` | Token de autenticación para SonarQube, usado en el análisis de calidad de código. |
| `SSH_PUBLIC_KEY_PROXY` | Clave pública SSH para el servidor proxy, necesaria para acceso remoto. |
| `SSH_PUBLIC_KEY_GENERAL` | Clave pública SSH para los servidores privados (app, workers, backend, db). |
| `SMTP_USERNAME` | Usuario del servidor SMTP para envío de notificaciones por email. |
| `SMTP_PASSWORD` | Contraseña del servidor SMTP para envío de notificaciones. |
| `NOTIFY_EMAIL` | Dirección de correo destino donde se envían las notificaciones del pipeline. |

### Configuración de secrets

```bash
# Desde GitHub CLI (requiere gh autenticado)
gh secret set AWS_REGION --body "us-east-1"
gh secret set AWS_ROLE_ARN --body "arn:aws:iam::123456789012:role/github-actions-terraform-role"
gh secret set SONAR_TOKEN --body "tu-token-sonarqube"
gh secret set SSH_PUBLIC_KEY_PROXY --body "$(cat ~/.ssh/id_rsa_proxy.pub)"
gh secret set SSH_PUBLIC_KEY_GENERAL --body "$(cat ~/.ssh/id_rsa_general.pub)"
gh secret set SMTP_USERNAME --body "usuario-smtp"
gh secret set SMTP_PASSWORD --body "password-smtp"
gh secret set NOTIFY_EMAIL --body "tu-email@dominio.com"
```

> Los secrets se configuran una sola vez en el repositorio de GitHub y se usan en todos los workflows sin necesidad de commitear valores sensibles.

### OIDC en AWS

La pipeline usa autenticación OIDC (OpenID Connect) para asumir un rol IAM en AWS sin necesidad de credenciales estáticas. El archivo `oidc_setup.tf` contiene la configuración base para crear el Identity Provider y el rol en AWS. Asegurate de completar el `thumbprint_list` y restringir la condición `StringLike` a tu organización/repositorio antes de aplicarlo.

## Decisiones técnicas

| Decisión | Justificación |
|---|---|
| Terraform modular | Reutilización, separación de responsabilidades y pruebas unitarias por módulo |
| Subredes públicas/privadas | Aislamiento de servicios; solo el proxy es accesible desde internet |
| Security Groups por servicio | Acceso granular, sin puertos abiertos a `0.0.0.0/0` innecesarios |
| IMDSv2 obligatorio | Cumplimiento con CIS AWS Foundations Benchmark |
| Backend S3 encriptado | Estado centralizado y protegido contra acceso no autorizado |
| EBS gp3 + encriptado | Rendimiento optimizado con cifrado en reposo |
| CI/CD automatizado | Validación de plan y seguridad antes de cualquier apply en AWS |

## Roadmap

- [ ] Agregar DynamoDB para locking del estado remoto
- [ ] Incorporar módulo de autoescalado (ASG) para workers
- [ ] Completar pipeline CI/CD con aprobación manual antes de `terraform apply`
- [ ] Agregar monitoreo con CloudWatch y alarmas básicas
- [ ] Migrar a Terraform Cloud/Enterprise para colaboración avanzada


