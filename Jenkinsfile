pipeline {
    agent any

    environment {
        // Docker Hub Variables
        DOCKERHUB_USER = "hassanmaher2001" 
        AI_IMG = "farmnet-ai-service"
        IOT_IMG = "farmnet-iot-service"
        FRONTEND_IMG = "farmnet-frontend" // الصورة الجديدة للويب سايت
        IMAGE_TAG = "${env.BUILD_ID}"
        
        // GitOps Repo
        GITOPS_REPO = "github.com/hassan-maher-dev/Smart-Farm-gitops.git"
        
        // Docker BuildKit (solves DooD issues)
        DOCKER_BUILDKIT = "0"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "📥 Checking out the main repository..."
                checkout scm
            }
        }

        // ==========================================
        // STAGE 1: BUILD DOCKER IMAGES (AI, IoT, Frontend)
        // ==========================================
        stage('Build Docker Images') {
            steps {
                echo "🐳 Building Docker images for AI, IoT, and Frontend services..."
                
                // 1. Build AI Service
                dir('Smart-Farm-Backend/ai_service') {
                    sh "docker build -t ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG} ${DOCKERHUB_USER}/${AI_IMG}:latest"
                }

                // 2. Build IoT Service
                dir('Smart-Farm-Backend/iot_service') {
                    sh "docker build -t ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG} ${DOCKERHUB_USER}/${IOT_IMG}:latest"
                }

                // 3. Build Frontend Service (Flutter + NGINX)
                dir('Smart-Farm-Flutter') {
                    sh "docker build -t ${DOCKERHUB_USER}/${FRONTEND_IMG}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKERHUB_USER}/${FRONTEND_IMG}:${IMAGE_TAG} ${DOCKERHUB_USER}/${FRONTEND_IMG}:latest"
                }
            }
        }

        // ==========================================
        // STAGE 2: PUSH TO DOCKERHUB
        // ==========================================
        stage('Push to DockerHub') {
            steps {
                echo "⬆️ Pushing images to DockerHub..."
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    
                    // Push AI
                    sh "docker push ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG}"
                    sh "docker push ${DOCKERHUB_USER}/${AI_IMG}:latest"
                    
                    // Push IoT
                    sh "docker push ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG}"
                    sh "docker push ${DOCKERHUB_USER}/${IOT_IMG}:latest"

                    // Push Frontend
                    sh "docker push ${DOCKERHUB_USER}/${FRONTEND_IMG}:${IMAGE_TAG}"
                    sh "docker push ${DOCKERHUB_USER}/${FRONTEND_IMG}:latest"
                }
            }
        }

        // ==========================================
        // STAGE 3: GITOPS WORKFLOW (UPDATE ARGO CD)
        // ==========================================
        stage('Update GitOps Manifests') {
            steps {
                echo "🔄 Updating Kubernetes Manifests for ArgoCD..."
                withCredentials([usernamePassword(credentialsId: 'github-token', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                    sh '''
                        git clone https://$GIT_USERNAME:$GIT_PASSWORD@${GITOPS_REPO}
                        cd Smart-Farm-gitops
                        
                        git config user.email "jenkins@devops.com"
                        git config user.name "Jenkins CI"

                        # Update tags for AI, IoT, and Frontend
                        sed -i "s|image: ${DOCKERHUB_USER}/${AI_IMG}:.*|image: ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG}|g" deployment-ai.yaml
                        sed -i "s|image: ${DOCKERHUB_USER}/${IOT_IMG}:.*|image: ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG}|g" deployment-iot.yaml
                        sed -i "s|image: ${DOCKERHUB_USER}/${FRONTEND_IMG}:.*|image: ${DOCKERHUB_USER}/${FRONTEND_IMG}:${IMAGE_TAG}|g" frontend-deployment.yaml

                        git add deployment-ai.yaml deployment-iot.yaml frontend-deployment.yaml
                        
                        # Only commit and push if there are changes
                        git diff --staged --quiet || (git commit -m "Auto-update images to build ${IMAGE_TAG}" && git push origin main)
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "🧹 Cleaning up workspace and local Docker images..."
            // تنظيف مساحة سيرفر Jenkins من الصور القديمة
            sh "docker rmi ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG} || true"
            sh "docker rmi ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG} || true"
            sh "docker rmi ${DOCKERHUB_USER}/${FRONTEND_IMG}:${IMAGE_TAG} || true"
            deleteDir()
        }
        success {
            echo "✅ SUCCESS: All Microservices (AI, IoT, Frontend) built, pushed, and GitOps updated!"
        }
        failure {
            echo "❌ FAILED: Pipeline execution encountered an error."
        }
    }
}