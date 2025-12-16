pipeline {
    agent {
        label 'local-agent'
    }
    
    environment {
        REGISTRY_URL = 'ghcr.io/ingasti'
        IMAGE_NAME = 'snappymail'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }
    
    options {
        timeout(time: 60, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    env.IMAGE_TAG = "${BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                    env.FULL_IMAGE = "${REGISTRY_URL}/${IMAGE_NAME}:branding"
                    echo "🚀 Building SnappyMail"
                    echo "Image: ${FULL_IMAGE}"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo "🔨 Building SnappyMail Docker image..."
                    sh """
                        docker build -t ${FULL_IMAGE} .
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            steps {
                script {
                    echo "📤 Pushing image to GitHub Container Registry..."
                    withCredentials([usernamePassword(credentialsId: 'ghcr-credentials', usernameVariable: 'GHCR_USER', passwordVariable: 'GHCR_TOKEN')]) {
                        sh '''
                            echo "${GHCR_TOKEN}" | docker login ghcr.io -u ${GHCR_USER} --password-stdin
                            docker push ${FULL_IMAGE}
                        '''
                    }
                }
            }
        }
        
        stage('Deploy') {
            steps {
                withCredentials([file(credentialsId: 'oci-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh 'kubectl apply -f k8s/deployment.yaml'
                    sh 'kubectl -n webmail rollout restart deployment/snappymail'
                    sh 'kubectl -n webmail rollout status deployment/snappymail --timeout=120s'
                }
            }
        }
    }
}
