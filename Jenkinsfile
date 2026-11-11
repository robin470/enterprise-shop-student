pipeline {
    agent any

    tools {
        jdk 'JDK21'
        maven 'Maven'
        nodejs 'Node20'
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        PATH+LOCAL = '/usr/local/bin:/opt/homebrew/bin'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=7 HEAD',
                        returnStdout: true
                    ).trim()
                }
                echo "Building image tag: ${env.IMAGE_TAG}"
            }
        }

        stage('Backend Build and Test') {
            steps {
                sh 'mvn -B clean verify'
            }
        }

        stage('Frontend Build') {
            steps {
                dir('frontend') {
                    sh 'npm ci'
                    sh 'npm run build'
                }
            }
        }

        stage('Build and Push Docker Images') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x

                        docker build -f services/api-gateway/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-api-gateway:$IMAGE_TAG" .

                        docker build -f services/user-service/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-user-service:$IMAGE_TAG" .

                        docker build -f services/product-service/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-product-service:$IMAGE_TAG" .

                        docker build -f services/order-service/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-order-service:$IMAGE_TAG" .

                        docker build -f services/payment-service/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-payment-service:$IMAGE_TAG" .

                        docker build -f services/notification-service/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-notification-service:$IMAGE_TAG" .

                        docker build -f frontend/Dockerfile \
                          -t "$DOCKERHUB_USER/enterprise-shop-frontend:$IMAGE_TAG" frontend

                        echo "$DOCKERHUB_TOKEN" | docker login \
                          -u "$DOCKERHUB_USER" --password-stdin

                        docker push "$DOCKERHUB_USER/enterprise-shop-api-gateway:$IMAGE_TAG"
                        docker push "$DOCKERHUB_USER/enterprise-shop-user-service:$IMAGE_TAG"
                        docker push "$DOCKERHUB_USER/enterprise-shop-product-service:$IMAGE_TAG"
                        docker push "$DOCKERHUB_USER/enterprise-shop-order-service:$IMAGE_TAG"
                        docker push "$DOCKERHUB_USER/enterprise-shop-payment-service:$IMAGE_TAG"
                        docker push "$DOCKERHUB_USER/enterprise-shop-notification-service:$IMAGE_TAG"
                        docker push "$DOCKERHUB_USER/enterprise-shop-frontend:$IMAGE_TAG"

                        docker logout
                    '''
                }
            }
        }
    }
}
