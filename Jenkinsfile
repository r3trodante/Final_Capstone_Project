pipeline {
    agent { 
        label 'nodegroup1' 
    }
    
    environment {
        // Define your Docker Hub registry information here
        DOCKER_USER = 'r3trodante'
        IMAGE_NAME  = 'final-capstone-prject-pipeline'
        IMAGE_TAG   = "${BUILD_NUMBER}" // Uses Jenkins build number as unique tag
        DOCKERHUB_REPO = 'r3trodante/final_capstone_project'
        DEPLOYMENT_SERVER = '172.31.6.123'
    }
    
    stages {
        stage('Code Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/r3trodante/Final_Capstone_Project.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'sonar' 
                    withSonarQubeEnv('sonar_server') { 
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=stat-check -Dsonar.projectName=Final_Capstone_Project -Dsonar.projectVersion=1.0 -Dsonar.sources=src/ -Dsonar.tests=test/ -Dsonar.test.inclusions=**/*.test.js"
                    }
                }
            }
        }

        stage('Docker Build Image') {
            steps {
                echo "Building the Docker image..."
                // Builds the Dockerfile located at the root of your project repository
                sh "docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} -t ${DOCKER_USER}/${IMAGE_NAME}:latest ."
            }
        }

        stage('Docker Push to Hub') {
            steps {
                // withCredentials securely injects your username/token into the block variables
                withCredentials([usernamePassword(credentialsId: 'docker_token', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    echo "Logging into Docker Hub..."
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    
                    echo "Pushing images to Docker Hub..."
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${DOCKER_USER}/${IMAGE_NAME}:latest"
                    
                    echo "Cleaning up local images..."
                    sh "docker rmi ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USER}/${IMAGE_NAME}:latest"
                }
            }
        }
         stage('Deploy to Production') {
            steps {
                echo "Deploying via Docker Compose over SSH..."
                
                sshagent(['deployment_server_ssh']) {
                    sh """
                        # 1. Copy the compose file over to the deployment server
                        scp -o StrictHostKeyChecking=no docker-compose.yml ubuntu@${DEPLOY_SERVER_IP}:/home/ubuntu/docker-compose.yml
                        
                        # 2. Log in and tell the deployment server's local engine to run it
                        ssh -o StrictHostKeyChecking=no ubuntu@${DEPLOY_SERVER_IP}'
                            export DOCKER_USER="${DOCKER_USER}"
                            export IMAGE_NAME="${IMAGE_NAME}"
                            export IMAGE_TAG="${IMAGE_TAG}"
                            
                            docker compose up -d --pull always
                            docker system prune -f
                        '
                    """
                }
            }
        }
    }
}
