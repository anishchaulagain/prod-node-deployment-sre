pipeline {
    agent{label 'prod-jenkins-node-1'}

    environment {
        // Load environment variables from .env file
        ENV_FILE = credentials('backend-env')
    }
    
    options {
        // Load environment variables from .env file at pipeline start
        timestamps()
    }
    
    //push test comment to trigger webhook
    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'cp $ENV_FILE .env'
                script {
                    // Load environment variables from .env file
                    def envVars = load('load-env.groovy').loadEnv()
                    
                    // Export key variables for use in pipeline
                    env.JENKINS_IMAGE_NAME = env.JENKINS_IMAGE_NAME ?: 'node-deploy'
                    env.JENKINS_CONTAINER_NAME = env.JENKINS_CONTAINER_NAME ?: 'express-api'
                    env.JENKINS_PORT = env.JENKINS_PORT ?: '8000'
                    env.JENKINS_DEPLOY_HOST = env.JENKINS_DEPLOY_HOST ?: '100.48.108.152'
                    env.JENKINS_DEPLOY_DIR = env.JENKINS_DEPLOY_DIR ?: '/home/ubuntu/deploy'
                    env.JENKINS_LOG_DIR = env.JENKINS_LOG_DIR ?: '/home/ubuntu/deploy/logs'
                    env.JENKINS_MAX_LOGS = env.JENKINS_MAX_LOGS ?: '5'
                    env.JENKINS_BACKUP_TAG = env.JENKINS_BACKUP_TAG ?: 'backup'
                    env.JENKINS_HEALTH_ENDPOINT = env.JENKINS_HEALTH_ENDPOINT ?: '/health'
                    
                    echo "✅ Environment variables loaded from .env file"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAGGED = "${env.JENKINS_IMAGE_NAME}:${commit}"

                    sh """
                        docker build -t ${env.IMAGE_TAGGED} -t ${env.JENKINS_IMAGE_NAME}:latest .
                    """
                }
            }
        }

        stage('Save Docker Image') {
            steps {
                sh "docker save ${env.IMAGE_TAGGED} -o image.tar"
            }
        }

        stage('Copy Image and .env to EC2') {
            steps {
                sshagent(['ec2-deploy-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ubuntu@${env.JENKINS_DEPLOY_HOST} "
                            mkdir -p ${env.JENKINS_DEPLOY_DIR} ${env.JENKINS_LOG_DIR} &&
                            chmod 755 ${env.JENKINS_DEPLOY_DIR} ${env.JENKINS_LOG_DIR}
                        "

                        scp -o StrictHostKeyChecking=no image.tar ubuntu@${env.JENKINS_DEPLOY_HOST}:${env.JENKINS_DEPLOY_DIR}/

                        ssh -o StrictHostKeyChecking=no ubuntu@${env.JENKINS_DEPLOY_HOST} "
                            [ -f ${env.JENKINS_DEPLOY_DIR}/.env ] && mv ${env.JENKINS_DEPLOY_DIR}/.env ${env.JENKINS_DEPLOY_DIR}/.env.bak || true
                        "

                        scp -o StrictHostKeyChecking=no \$ENV_FILE ubuntu@${env.JENKINS_DEPLOY_HOST}:${env.JENKINS_DEPLOY_DIR}/.env
                    """
                }
            }
        }

        stage('Deploy Backend on EC2 (Zero Downtime)') {
            steps {
                sshagent(['ec2-deploy-key']) {
                    sh """
ssh -o StrictHostKeyChecking=no ubuntu@${env.JENKINS_DEPLOY_HOST} 'bash -s' <<'EOF'
set -euo pipefail

DEPLOY_DIR=${env.JENKINS_DEPLOY_DIR}
LOG_DIR=${env.JENKINS_LOG_DIR}
PORT=${env.JENKINS_PORT}
CONTAINER_NAME=${env.JENKINS_CONTAINER_NAME}
IMAGE_TAG=${env.IMAGE_TAGGED}
HEALTH_ENDPOINT=${env.JENKINS_HEALTH_ENDPOINT}
BACKUP_TAG=${env.JENKINS_BACKUP_TAG}
MAX_LOGS=${env.JENKINS_MAX_LOGS}

TIMESTAMP=\$(date +%Y%m%d-%H%M%S)
NEW_CONTAINER="\${CONTAINER_NAME}-new"
OLD_CONTAINER="\${CONTAINER_NAME}"
BACKUP_CONTAINER="\${CONTAINER_NAME}-\${BACKUP_TAG}"

echo "📦 Loading Docker image..."
docker load -i \$DEPLOY_DIR/image.tar

echo "🛑 Stop existing container if present..."
if docker ps -a --format '{{.Names}}' | grep -w \$OLD_CONTAINER >/dev/null 2>&1; then
    docker stop \$OLD_CONTAINER || true
    docker rename \$OLD_CONTAINER \$BACKUP_CONTAINER || true
fi

echo "📝 Backup logs if backup container exists..."
if docker ps -a --format '{{.Names}}' | grep -w \$BACKUP_CONTAINER >/dev/null 2>&1; then
    docker logs \$BACKUP_CONTAINER > \$LOG_DIR/\${OLD_CONTAINER}-\${TIMESTAMP}.log || true
fi

echo "🚀 Starting new container..."
docker run -d \
    -p \$PORT:\$PORT \
    --env-file \$DEPLOY_DIR/.env \
    --name \$NEW_CONTAINER \
    \$IMAGE_TAG

echo "⏳ Waiting for health check..."
for i in {1..15}; do
    if curl -fs http://localhost:\$PORT\$HEALTH_ENDPOINT >/dev/null; then
        echo "✅ Health check passed"
        break
    fi

    if [ \$i -eq 15 ]; then
        echo "❌ Health check failed → rollback"
        docker stop \$NEW_CONTAINER || true
        docker rm \$NEW_CONTAINER || true

        if docker ps -a --format '{{.Names}}' | grep -w \$BACKUP_CONTAINER >/dev/null 2>&1; then
            docker rename \$BACKUP_CONTAINER \$OLD_CONTAINER || true
            docker start \$OLD_CONTAINER || true
        fi

        exit 1
    fi

    sleep 2
done

echo "🔁 Swapping containers..."
docker rename \$NEW_CONTAINER \$OLD_CONTAINER

echo "🧹 Removing old backup container..."
docker rm -f \$BACKUP_CONTAINER >/dev/null 2>&1 || true

echo "🧹 Cleaning old logs..."
cd \$LOG_DIR
ls -1t | tail -n +\$((MAX_LOGS + 1)) | xargs -r rm -f || true

echo "🎉 Deployment successful"
EOF
"""
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment completed successfully with zero downtime!"
        }
        failure {
            echo "❌ Deployment failed! Check logs and containers on EC2."
        }
    }
}
