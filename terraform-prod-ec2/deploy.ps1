# Terraform deployment script with environment variables from .env (PowerShell)
# Usage: .\deploy.ps1 plan|apply|destroy

param(
    [Parameter(Position=0)]
    [ValidateSet('init', 'plan', 'apply', 'destroy')]
    [string]$Command = 'plan'
)

$ErrorActionPreference = 'Stop'

# Load environment variables from .env file
$envFilePath = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath '.env'

if (Test-Path $envFilePath) {
    Write-Host "🔧 Loading environment variables from .env..." -ForegroundColor Green
    
    Get-Content $envFilePath | ForEach-Object {
        # Skip empty lines and comments
        if ($_ -and -not $_.StartsWith('#')) {
            $parts = $_ -split '=', 2
            if ($parts.Count -eq 2) {
                $key = $parts[0].Trim()
                $value = $parts[1].Trim().Trim('"', "'")
                [Environment]::SetEnvironmentVariable($key, $value, 'Process')
            }
        }
    }
} else {
    Write-Host "⚠️  Warning: .env file not found at $envFilePath" -ForegroundColor Yellow
    exit 1
}

# Display loaded Terraform variables
Write-Host "✅ Environment variables loaded:" -ForegroundColor Green
Get-ChildItem Env: | Where-Object { $_.Name -match '^TF_' } | Sort-Object Name | ForEach-Object {
    Write-Host "  $($_.Name) = $($_.Value)"
}

# Initialize Terraform if not already initialized
if (-not (Test-Path '.terraform')) {
    Write-Host "🔧 Initializing Terraform..." -ForegroundColor Cyan
    terraform init
}

# Common Terraform variables
$terraformVars = @(
    "-var=aws_region=$([Environment]::GetEnvironmentVariable('TF_AWS_REGION', 'Process') ?? 'us-east-1')"
    "-var=instance_type=$([Environment]::GetEnvironmentVariable('TF_INSTANCE_TYPE', 'Process') ?? 't3.micro')"
    "-var=instance_count=$([Environment]::GetEnvironmentVariable('TF_INSTANCE_COUNT', 'Process') ?? '3')"
    "-var=app_port=$([Environment]::GetEnvironmentVariable('TF_APP_PORT', 'Process') ?? '8000')"
)

$keyName = [Environment]::GetEnvironmentVariable('TF_KEY_NAME', 'Process')
if (-not $keyName) {
    Write-Host "❌ Error: TF_KEY_NAME not set in .env file" -ForegroundColor Red
    exit 1
}
$terraformVars += "-var=key_name=$keyName"

# Run terraform commands
switch ($Command) {
    'init' {
        Write-Host "🔧 Initializing Terraform..." -ForegroundColor Cyan
        terraform init
    }
    'plan' {
        Write-Host "📋 Planning Terraform changes..." -ForegroundColor Cyan
        terraform plan @terraformVars
    }
    'apply' {
        Write-Host "🚀 Applying Terraform changes..." -ForegroundColor Cyan
        terraform apply @terraformVars -auto-approve
    }
    'destroy' {
        Write-Host "⚠️  Destroying Terraform infrastructure..." -ForegroundColor Yellow
        terraform destroy @terraformVars -auto-approve
    }
}

Write-Host "✅ Terraform operation completed!" -ForegroundColor Green
