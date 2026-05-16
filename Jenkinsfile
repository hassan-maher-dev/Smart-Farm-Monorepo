pipeline {
    agent any

    environment {
        // Docker Hub Variables
        DOCKERHUB_USER = "hassanmaher2001" // غيره باسمك على Docker Hub
        AI_IMG = "farmnet-ai-service"
        IOT_IMG = "farmnet-iot-service"
        IMAGE_TAG = "${env.BUILD_ID}"
        
        // AWS Variables (For Flutter Web Upload)
        AWS_REGION = "us-east-1"
        S3_BUCKET_NAME = "my-eks-project-dev-frontend-bucket" // نفس الاسم اللي طلع في Outputs بتاعت Terraform
        
        // GitOps Repo
        GITOPS_REPO = "github.com/hassan-maher-dev/Smart-Farm-GitOps.git"
        
        // Docker BuildKit (solves DooD issues)
        DOCKER_BUILDKIT = "0"
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo "📥 Checking out the main repository..."
                // هنا Jenkins بيعمل Checkout للكود تلقائياً لو الـ Jenkinsfile ده موجود جوه الريبو
                checkout scm
            }
        }

        // ==========================================
        // STAGE 1: BUILD & PUSH BACKEND (DOCKER)
        // ==========================================
        stage('Build Docker Images (AI & IoT)') {
            steps {
                echo "🐳 Building Docker images for AI and IoT services..."
                
                // الدخول لمجلد الباك إند وبناء الـ AI Service
                dir('Smart-Farm-Backend/ai_service') {
                    sh "docker build -t ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG} ."
                    // تاج إضافي للـ latest
                    sh "docker tag ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG} ${DOCKERHUB_USER}/${AI_IMG}:latest"
                }

                // الدخول لمجلد الباك إند وبناء الـ IoT Service
                dir('Smart-Farm-Backend/iot_service') {
                    sh "docker build -t ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG} ."
                    sh "docker tag ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG} ${DOCKERHUB_USER}/${IOT_IMG}:latest"
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo "⬆️ Pushing images to DockerHub..."
                // لازم تكون عامل Credentials في Jenkins باسم dockerhub-creds
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASS', usernameVariable: 'DOCKER_USER')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    
                    sh "docker push ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG}"
                    sh "docker push ${DOCKERHUB_USER}/${AI_IMG}:latest"
                    
                    sh "docker push ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG}"
                    sh "docker push ${DOCKERHUB_USER}/${IOT_IMG}:latest"
                }
            }
        }

        // ==========================================
        // STAGE 2: BUILD & DEPLOY FRONTEND (FLUTTER)
        // ==========================================
        stage('Build Flutter Web') {
            // بنستخدم Docker Image جاهزة للـ Flutter عشان مش نحتاج نسطبه على سيرفر Jenkins
            agent {
                docker {
                    image 'ghcr.io/cirruslabs/flutter:3.24.0' // استخدم إصدار متوافق مع كودك
                    reuseNode true
                }
            }
            steps {
                echo "📱 Building Flutter Web application..."
                dir('Smart-Farm-Flutter') {
                    // تنزيل المكتبات
                    sh "flutter pub get"
                    // بناء نسخة الويب
                    sh "flutter build web --release"
                }
            }
        }

        stage('Deploy Web to AWS S3') {
            steps {
                echo "☁️ Uploading Flutter Web build to AWS S3..."
                // لازم تكون عامل Credentials في Jenkins باسم aws-credentials-id (نوعها AWS Credentials)
                withAWS(credentials: 'aws-credentials-id', region: "${AWS_REGION}") {
                    dir('Smart-Farm-Flutter/build/web') {
                        // رفع الملفات للـ S3
                        sh "aws s3 sync . s3://${S3_BUCKET_NAME} --delete"
                        
                        // أمر إضافي لمسح الكاش من CloudFront لو معاك الـ Distribution ID (اختياري بس مستحسن جداً)
                        // sh "aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths '/*'"
                    }
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
                        cd Smart-Farm-GitOps
                        
                        git config user.email "jenkins@devops.com"
                        git config user.name "Jenkins CI"

                        # Update tags for both services in the deployment yamls
                        sed -i "s|image: ${DOCKERHUB_USER}/${AI_IMG}:.*|image: ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG}|g" k8s/ai-deployment.yaml
                        sed -i "s|image: ${DOCKERHUB_USER}/${IOT_IMG}:.*|image: ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG}|g" k8s/iot-deployment.yaml

                        git add k8s/ai-deployment.yaml k8s/iot-deployment.yaml
                        
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
            // تنظيف مساحة سيرفر Jenkins
            sh "docker rmi ${DOCKERHUB_USER}/${AI_IMG}:${IMAGE_TAG} || true"
            sh "docker rmi ${DOCKERHUB_USER}/${IOT_IMG}:${IMAGE_TAG} || true"
            cleanWs()
        }
        success {
            echo "✅ SUCCESS: Backend images pushed, Frontend deployed to S3, and GitOps updated!"
        }
        failure {
            echo "❌ FAILED: Pipeline execution encountered an error."
        }
    }
}