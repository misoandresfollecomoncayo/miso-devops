# PASO 1: Roles IAM para CodeDeploy-ECS

## 🎯 Objetivo

Crear el rol IAM que permitirá a AWS CodeDeploy realizar despliegues Blue/Green en Amazon ECS.

## 📋 ¿Qué se crea?

1. **IAM Role**: `python-app-dev-codedeploy-ecs-role`
2. **3 Políticas adjuntas**:
   - AWSCodeDeployRoleForECS
   - ElasticLoadBalancingFullAccess
   - AmazonECS_FullAccess

## 🚀 Cómo usar

### 1. Configurar variables

Edita `terraform.tfvars` con tus valores:
```bash
nano terraform.tfvars
```

### 2. Inicializar Terraform
```bash
terraform init
```

### 3. Ver el plan
```bash
terraform plan
```

### 4. Aplicar cambios
```bash
terraform apply
```

### 5. Ver resultados
```bash
terraform output
```

## 📊 Recursos creados

- 1 IAM Role
- 3 Policy Attachments

**Costo:** $0.00 (IAM es gratuito)

## ✅ Verificación

Verifica el rol en AWS Console:
[Ver rol en IAM](https://console.aws.amazon.com/iam/home#/roles)

O con AWS CLI:
```bash
aws iam get-role --role-name python-app-dev-codedeploy-ecs-role
```

## 🔄 Siguientes pasos

Una vez completado, guarda el ARN del rol:
```bash
terraform output codedeploy_role_arn
```

Lo necesitarás en el **Paso 7: CodeDeploy**.

## 🧹 Limpieza

Para eliminar el rol:
```bash
terraform destroy
```