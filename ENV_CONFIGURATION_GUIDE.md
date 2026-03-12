# Environment Configuration Guide

This document explains how to configure Jenkins and Terraform environments using the `.env` file.

## Overview

All Jenkins and Terraform environment variables are now centralized in the `.env` file at the project root. This ensures:

- Single source of truth for all configuration
- Easy management of credentials and settings
- Consistency across Jenkins pipelines and Terraform deployments

## Configuration File Structure

### .env File Location

```
prod-node-deploy/
├── .env                           # Main environment configuration file
├── Jenkinsfile                    # Updated to use .env variables
├── load-env.groovy               # Jenkins helper script for loading .env
├── terraform-prod-ec2/
│   ├── deploy.sh                 # Linux/Mac Terraform deployment script
│   ├── deploy.ps1                # Windows PowerShell Terraform script
│   └── terraform.tfvars          # Terraform variables file
└── ...
```

## .env File Variables

### Jenkins Configuration

```dotenv
# Docker Configuration
JENKINS_IMAGE_NAME=node-deploy           # Docker image name
JENKINS_CONTAINER_NAME=express-api       # Container name on EC2
JENKINS_PORT=8000                        # Application port

# EC2 Deployment Configuration
JENKINS_DEPLOY_HOST=     # EC2 instance IP/hostname
JENKINS_DEPLOY_DIR=/home/ubuntu/deploy   # Deployment directory on EC2
JENKINS_LOG_DIR=/home/ubuntu/deploy/logs # Log directory on EC2
JENKINS_MAX_LOGS=5                       # Number of logs to keep
JENKINS_BACKUP_TAG=backup                # Backup container tag
JENKINS_HEALTH_ENDPOINT=/health          # Health check endpoint
```

### Terraform Configuration

```dotenv
# AWS Configuration
TF_AWS_REGION=us-east-1                  # AWS region
TF_INSTANCE_TYPE=t3.micro                # EC2 instance type
TF_KEY_NAME=your-ec2-key-pair-name       # EC2 key pair name (REQUIRED)
TF_INSTANCE_COUNT=3                      # Number of instances to create
TF_APP_PORT=8000                         # Application port

# Security Group Configuration
TF_SG_NAME=basic-ec2-sg                  # Security group name
TF_SG_DESCRIPTION=Allow SSH and app port # Security group description

# EC2 Instance Configuration
TF_INSTANCE_NAME_PREFIX=basic-ec2        # Instance name prefix
```

### Database Configuration (Existing)

```dotenv
# Database Configuration
DB_TYPE=mysql
DB_HOST=
DB_USER=
DB_PASSWORD=
DB_NAME=
```

## Usage

### Jenkins Pipeline

The Jenkinsfile automatically loads variables from the `.env` file during the "Checkout" stage using the `load-env.groovy` helper script. No manual action required.

**Key points:**

- Variables are loaded into the Jenkins environment with `JENKINS_*` prefix
- If a variable is not found, a default value is used (see `Jenkinsfile` Checkout stage)
- All Terraform variables are also available with `TF_*` prefix

### Terraform Deployment

#### Option 1: Linux/Mac

```bash
cd terraform-prod-ec2
chmod +x deploy.sh
./deploy.sh plan    # View changes
./deploy.sh apply   # Apply changes
./deploy.sh destroy # Destroy infrastructure
```

#### Option 2: Windows PowerShell

```powershell
cd terraform-prod-ec2
.\deploy.ps1 plan    # View changes
.\deploy.ps1 apply   # Apply changes
.\deploy.ps1 destroy # Destroy infrastructure
```

#### Option 3: Manual Terraform Commands

```bash
# Load variables from .env
set -a
source ../.env
set +a

# Run terraform with variables
terraform plan \
  -var="aws_region=${TF_AWS_REGION}" \
  -var="instance_type=${TF_INSTANCE_TYPE}" \
  -var="key_name=${TF_KEY_NAME}"
```

## Environment Setup Instructions

### Step 1: Update .env File

Update the `.env` file with your actual configuration values:

```bash
# Edit the .env file
nano .env  # Linux/Mac
# or
code .env  # VS Code
```

**Critical settings to update:**

1. **JENKINS_DEPLOY_HOST** - Your EC2 instance IP address
2. **TF_KEY_NAME** - Your AWS EC2 key pair name (this is required for Terraform)

### Step 2: Verify Environment Variables

**For Jenkins:**
The pipeline will display loaded variables in the "Checkout" stage logs.

**For Terraform:**

```bash
# Verify before deployment
cd terraform-prod-ec2

# Linux/Mac
source ../.env && terraform plan -var="key_name=${TF_KEY_NAME}"

# Windows PowerShell
.\deploy.ps1 plan
```

## Security Considerations

### Important Rules

1. **Never commit `.env` to version control** if it contains secrets
2. **Use Jenkins Secrets** for sensitive data (passwords, API keys)
3. **Rotate credentials regularly** for the AWS key pair
4. **Restrict file permissions** on `.env` file (chmod 600 on Linux)

### Best Practices

1. Use **AWS IAM roles** instead of hardcoded credentials when possible
2. Store sensitive variables in **Jenkins Credentials Manager**
3. Use **AWS Secrets Manager** for production secrets
4. Implement **access controls** on EC2 instances
5. Use **terraform.tfstate encryption** for sensitive state data

## Troubleshooting

### Jenkins: Variables not loading

**Error:** `JENKINS_DEPLOY_HOST: not found`

**Solution:**

1. Verify `.env` file exists in the workspace
2. Check Jenkins has read permissions on `.env`
3. Verify variable names in `.env` match expected names
4. Check logs in the "Checkout" stage

### Terraform: Key pair not found

**Error:** `Error: Error importing EC2 key pair: InvalidKeyPair.NotFound`

**Solution:**

1. Verify `TF_KEY_NAME` is set in `.env`
2. Confirm the key pair exists in your AWS account
3. Verify you're using the correct AWS region (`TF_AWS_REGION`)

### Terraform: Permission denied

**Error:** `Error: Error creating security group: UnauthorizedOperation`

**Solution:**

1. Verify AWS credentials are configured
2. Check IAM permissions for EC2 operations
3. Ensure the AWS user has `ec2:*` permissions

## Examples

### Example 1: Deploying to Production

```bash
# 1. Update .env with production values
JENKINS_DEPLOY_HOST=prod-ec2.example.com
TF_INSTANCE_COUNT=5
TF_INSTANCE_TYPE=t3.small

# 2. Run Jenkins pipeline (automatic)
# Pipeline loads .env variables automatically

# 3. Verify Terraform plan
cd terraform-prod-ec2
./deploy.sh plan

# 4. Apply changes
./deploy.sh apply
```

### Example 2: Scaling Infrastructure

```bash
# 1. Update instance count in .env
TF_INSTANCE_COUNT=10

# 2. Apply Terraform changes
./deploy.sh apply
```

### Example 3: Changing Region

```bash
# 1. Update region in .env
TF_AWS_REGION=us-west-2
TF_KEY_NAME=us-west-2-key  # Update key for new region

# 2. Re-initialize and apply
./deploy.sh init
./deploy.sh plan
./deploy.sh apply
```

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [DotEnv Best Practices](https://12factor.net/config)

## Support

For issues or questions:

1. Check the Troubleshooting section above
2. Review logs in Jenkins pipeline
3. Run `terraform plan` to see detailed error messages
4. Verify all required environment variables are set in `.env`
