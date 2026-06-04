pipeline {
    agent any
    tools {
        nodejs 'nodejs'
    }
    environment {
        AWS_REGION   = 'ap-south-1'
        ECR_REPO     = '322236400881.dkr.ecr.ap-south-1.amazonaws.com/bytesapp'
        IMAGE_TAG    = "${env.BUILD_NUMBER}"
        EC2_INSTANCE = credentials('ec2-instance-id')
    }
    stages {
        stage('Checkout') {
            steps {
                cleanWs()
                checkout scm
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Run Tests') {
            steps {
                sh 'npm test'
            }
            post {
                failure {
                    echo 'Tests failed! Stopping pipeline.'
                }
            }
        }
        stage('Vulnerability Scan - Dependencies') {
            steps {
                sh '''
                    if ! command -v trivy &> /dev/null; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /var/lib/jenkins/bin
                    fi
                    export PATH=$PATH:/var/lib/jenkins/bin
                    trivy fs \
                        --exit-code 0 \
                        --severity HIGH,CRITICAL \
                        --no-progress \
                        --scanners vuln \
                        .
                '''
            }
            post {
                always {
                    echo 'Dependency vulnerability scan complete'
                }
            }
        }
        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t bytesapp:${IMAGE_TAG} .
                    docker tag bytesapp:${IMAGE_TAG} ${ECR_REPO}:${IMAGE_TAG}
                    docker tag bytesapp:${IMAGE_TAG} ${ECR_REPO}:latest
                """
            }
        }
        stage('Vulnerability Scan - Container') {
            steps {
                sh """
                    export PATH=\$PATH:/var/lib/jenkins/bin
                    trivy image \
                        --exit-code 0 \
                        --severity HIGH,CRITICAL \
                        --no-progress \
                        --scanners vuln \
                        bytesapp:${IMAGE_TAG}
                """
            }
            post {
                always {
                    echo 'Container vulnerability scan complete'
                }
            }
        }
        stage('Push to ECR') {
            steps {
                sh """
                    aws ecr get-login-password --region ${AWS_REGION} | \
                    docker login --username AWS --password-stdin ${ECR_REPO}
                    docker push ${ECR_REPO}:${IMAGE_TAG}
                    docker push ${ECR_REPO}:latest
                """
            }
        }
        stage('Deploy to Staging') {
            steps {
                sh """
                    aws ssm send-command \
                        --instance-ids ${EC2_INSTANCE} \
                        --document-name "AWS-RunShellScript" \
                        --region ${AWS_REGION} \
                        --parameters commands='[
                            "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}",
                            "docker pull ${ECR_REPO}:latest",
                            "docker stop bytesapp || true",
                            "docker rm bytesapp || true",
                            "docker run -d --name bytesapp -p 3000:3000 ${ECR_REPO}:latest"
                        ]' \
                        --output text
                """
            }
        }
        stage('Manual Approval') {
            steps {
                input message: 'Deploy to production?', ok: 'Yes, deploy!'
            }
        }
        stage('Deploy to Production') {
            steps {
                echo 'Production deployment approved!'
                echo 'In real setup: deploy to production EC2 here'
            }
        }
    }
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            mail to: 'vigneshwaravindran@gmail.com',
                 subject: "Pipeline FAILED - ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: """
                    Build failed!
                    Job: ${env.JOB_NAME}
                    Build: ${env.BUILD_NUMBER}
                    URL: ${env.BUILD_URL}
                    Please check console output for details.
                 """
        }
    }
}
