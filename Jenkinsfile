pipeline {
  agent any

  environment {
    IMAGE_NAME = 'full-node-js-pipeline:latest'
    DOCKERHUB_CREDENTIALS = 'docker_token'
    DOCKERHUB_REPO = 'r3trodante/full_cicd_pipleline'
    SONAR_TOKEN = credentials('sonar_key')
  }

  stages {
    stage('Code Checkout') {
      steps {
        git branch: 'main', url: 'https://github.com/r3trodante/Full_CI-CD_pipeline_demo.git'
      }
    }

    stage('SonarQube Analysis') {
        steps {
            script {
                // Ensure 'sonar' matches the name in Global Tool Configuration
                def scannerHome = tool 'sonar' 
                
                withSonarQubeEnv('sonar_server') { 
                    bat """
                        "${scannerHome}\\bin\\sonar-scanner.bat" ^
                        -Dsonar.projectKey=demo-check ^
                        -Dsonar.projectName="SonarQube Jenkins Demo" ^
                        -Dsonar.projectVersion=1.0 ^
                        -Dsonar.sources=src/ ^
                        -Dsonar.tests=test/ ^
                        -Dsonar.test.inclusions=**/*.test.js
                    """
                }
            }
        }
    }

    stage('Build Docker Image') {
      steps {
        // Use %VAR% for environment variables in bat
        bat "docker build -t %IMAGE_NAME% ."
      }
    }

    stage('Docker Login and Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          bat """
            docker login -u %DOCKER_USER% -p %DOCKER_PASS%
            docker tag %IMAGE_NAME% %DOCKERHUB_REPO%:latest
            docker push %DOCKERHUB_REPO%:latest
          """
        }
      }
    }

    stage('Pull Docker Image') {
      steps {
        bat "docker pull %DOCKERHUB_REPO%:latest"
      }
    }

    stage('Deploy Docker Container') {
      steps {
        // Added a cleanup step to remove old container if it exists
        bat """
            docker stop dante-full-cicd-container || rem
            docker rm dante-full-cicd-container || rem
            docker run -d -p 80:3000 --name dante-full-cicd-container %DOCKERHUB_REPO%:latest
        """
      }
    }
  }
}
