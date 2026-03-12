#!/bin/bash
# Terraform deployment script with environment variables from .env

set -euo pipefail

# Load environment variables from .env file
if [ -f ../.env ]; then
    echo "Loading environment variables from .env..."
    export $(grep '^TF_' ../.env | xargs)
else
    echo "Warning: .env file not found in parent directory"
    exit 1
fi

# Display loaded Terraform variables
echo "✅ Environment variables loaded:"
env | grep '^TF_' | sort || true

# Initialize Terraform if not already initialized
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Run terraform commands
case "${1:-plan}" in
    init)
        terraform init
        ;;
    plan)
        echo "📋 Planning Terraform changes..."
        terraform plan \
            -var="aws_region=${TF_AWS_REGION:-us-east-1}" \
            -var="instance_type=${TF_INSTANCE_TYPE:-t3.micro}" \
            -var="instance_count=${TF_INSTANCE_COUNT:-3}" \
            -var="app_port=${TF_APP_PORT:-8000}" \
            -var="key_name=${TF_KEY_NAME:?TF_KEY_NAME not set in .env file}"
        ;;
    apply)
        echo "🚀 Applying Terraform changes..."
        terraform apply \
            -var="aws_region=${TF_AWS_REGION:-us-east-1}" \
            -var="instance_type=${TF_INSTANCE_TYPE:-t3.micro}" \
            -var="instance_count=${TF_INSTANCE_COUNT:-3}" \
            -var="app_port=${TF_APP_PORT:-8000}" \
            -var="key_name=${TF_KEY_NAME:?TF_KEY_NAME not set in .env file}" \
            -auto-approve
        ;;
    destroy)
        echo "⚠️  Destroying Terraform infrastructure..."
        terraform destroy \
            -var="aws_region=${TF_AWS_REGION:-us-east-1}" \
            -var="instance_type=${TF_INSTANCE_TYPE:-t3.micro}" \
            -var="instance_count=${TF_INSTANCE_COUNT:-3}" \
            -var="app_port=${TF_APP_PORT:-8000}" \
            -var="key_name=${TF_KEY_NAME:?TF_KEY_NAME not set in .env file}" \
            -auto-approve
        ;;
    *)
        echo "Usage: $0 {init|plan|apply|destroy}"
        exit 1
        ;;
esac

echo "✅ Terraform operation completed!"
