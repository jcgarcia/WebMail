pipeline {
    agent any
    
    options {
        timeout(time: 15, unit: 'MINUTES')
    }
    
    stages {
        stage('Deploy') {
            steps {
                checkout scm
                withCredentials([file(credentialsId: 'oci-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -f k8s/deployment.yaml'
                    sh 'kubectl -n webmail rollout restart deployment/snappymail'
                    sh 'kubectl -n webmail rollout status deployment/snappymail --timeout=120s'
                }
            }
        }
    }
}
