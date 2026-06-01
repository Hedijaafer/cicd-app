pipeline {
    agent any

    environment {
        DOCKER_IMAGE    = "yourdockerhubusername/cicd-flask-app"
        DOCKER_TAG      = "${env.BUILD_NUMBER}"
        DOCKER_REGISTRY = "https://index.docker.io/v1/"
    }

    stages {

        stage('Checkout') {
            steps {
                echo '==> Cloning repository from GitHub...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo '==> Installing Python dependencies...'
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Run Tests') {
            steps {
                echo '==> Running unit tests with coverage...'
                sh '''
                    . venv/bin/activate
                    python -m pytest tests/ -v \
                        --tb=short \
                        --junitxml=test-results.xml \
                        --cov=app \
                        --cov-report=xml:coverage.xml \
                        --cov-report=term-missing
                '''
            }
            post {
                always {
                    junit 'test-results.xml'
                    publishCoverage adapters: [coberturaAdapter('coverage.xml')]
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "==> Building Docker image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '==> Pushing Docker image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                echo '==> Deploying container...'
                sh '''
                    docker stop cicd-flask-app || true
                    docker rm   cicd-flask-app || true
                    docker run -d \
                        --name cicd-flask-app \
                        --restart unless-stopped \
                        -p 5000:5000 \
                        ${DOCKER_IMAGE}:${DOCKER_TAG}
                    echo "App deployed at http://localhost:5000"
                '''
            }
        }
    }

    post {
        success {
            echo "Pipeline SUCCESS — build #${env.BUILD_NUMBER} deployed."
        }
        failure {
            echo "Pipeline FAILED — check console output above."
        }
        always {
            sh 'docker logout || true'
            cleanWs()
        }
    }
}
