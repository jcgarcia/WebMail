pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 10, unit: 'MINUTES')
    }
    
    environment {
        IMAGE = 'djmaze/snappymail:latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    echo "🚀 Deploying SnappyMail WebMail"
                    echo "=============================="
                    echo "📦 Image: ${IMAGE}"
                }
            }
        }
        
        stage('Deploy to K8s') {
            steps {
                withCredentials([file(credentialsId: 'oci-kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "☸️ Deploying to Kubernetes..."
                        
                        // Create namespace if not exists
                        sh '''
                            kubectl get namespace webmail || kubectl create namespace webmail
                        '''
                        
                        // Apply manifests (only yaml files)
                        sh '''
                            kubectl apply -f k8s/deployment.yaml
                        '''
                        
                        // Wait for rollout
                        sh '''
                            kubectl -n webmail rollout status deployment/snappymail --timeout=120s
                        '''
                        
                        // Get service info
                        sh '''
                            echo "Service Info:"
                            kubectl -n webmail get svc snappymail -o wide
                            echo ""
                            echo "Pod Status:"
                            kubectl -n webmail get pods -l app=snappymail
                        '''
                        
                        echo "✅ Deployment successful"
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "🎉 Pipeline successful - SnappyMail deployed to webmail namespace"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}
