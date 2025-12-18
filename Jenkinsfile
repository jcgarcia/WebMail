pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 15, unit: 'MINUTES')
    }
    
    stages {
        stage('Deploy') {
            steps {
                checkout scm
                withCredentials([file(credentialsId: 'oci-kubeconfig', variable: 'KUBECONFIG')]) {
                    script {
                        echo "☸️  Deploying jasonmun/snappymail:latest..."
                        sh 'kubectl apply -f k8s/deployment.yaml'
                        sh 'kubectl -n webmail rollout status deployment/snappymail --timeout=120s'
                        echo "✅ Deployment successful"
                    }
                }
            }
        }
    }
    
    post {
        failure {
            echo "❌ Deployment failed"
        }
    }
}
