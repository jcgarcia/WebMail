pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }
    
    environment {
        REGISTRY = 'ghcr.io'
        IMAGE_NAME = 'ghcr.io/jcgarcia/webmail'
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    echo "🚀 Building Custom SnappyMail WebMail"
                    echo "======================================"
                    echo "📦 Image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Git Commit: ${GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    sh '''
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} \
                                     -t ${IMAGE_NAME}:latest \
                                     --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                                     --build-arg VCS_REF=${GIT_COMMIT_SHORT} \
                                     .
                    '''
                    echo "✅ Image built successfully"
                }
            }
        }
        
        stage('Push to GitHub Registry') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ghcr-credentials', usernameVariable: 'GHCR_USER', passwordVariable: 'GHCR_TOKEN')]) {
                    script {
                        echo "📤 Logging in to GitHub Container Registry..."
                        sh '''
                            echo $GHCR_TOKEN | docker login ${REGISTRY} -u $GHCR_USER --password-stdin
                        '''
                        
                        echo "📤 Pushing image to registry..."
                        sh '''
                            docker push ${IMAGE_NAME}:${IMAGE_TAG}
                            docker push ${IMAGE_NAME}:latest
                        '''
                        
                        echo "✅ Image pushed successfully"
                    }
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                withCredentials([file(credentialsId: 'oci-kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "☸️  Deploying to Kubernetes..."
                        
                        // Create namespace if not exists
                        sh '''
                            kubectl get namespace webmail || kubectl create namespace webmail
                        '''
                        
                        // Apply manifests
                        sh '''
                            kubectl apply -f k8s/deployment.yaml
                        '''
                        
                        // Update image with new build
                        sh '''
                            kubectl -n webmail set image deployment/snappymail \
                                snappymail=${IMAGE_NAME}:${IMAGE_TAG} \
                                --record
                        '''
                        
                        // Wait for rollout
                        sh '''
                            kubectl -n webmail rollout status deployment/snappymail --timeout=120s
                        '''
                        
                        // Verify deployment
                        sh '''
                            echo "Service Info:"
                            kubectl -n webmail get svc snappymail -o wide
                            echo ""
                            echo "Pod Status:"
                            kubectl -n webmail get pods -l app=snappymail
                            echo ""
                            echo "Pod Logs (last 20 lines):"
                            kubectl -n webmail logs -l app=snappymail --tail=20
                        '''
                        
                        echo "✅ Deployment successful"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline successful - WebMail ${IMAGE_TAG} deployed to K8s"
        }
        failure {
            echo "❌ Pipeline failed"
        }
        always {
            cleanWs()
        }
    }
}

