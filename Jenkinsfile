// Jenkins pipeline for building, pushing, deploying, and verifying a Dockerized app on AWS ECS.
// Stages:
// - Build Docker Image: Builds the Docker image with the Jenkins build number as tag.
// - Push to ECR: Authenticates and pushes the image to AWS ECR.
// - Deploy to ECS: Updates ECS task definition and service with the new image.
// - Verify Health: Runs a shell script to check application health via HTTP endpoint.
// - Notify SNS: Sends a notification to an SNS topic on pipeline success.
// - Pipeline Logging: Uploads Docker image list to S3 for audit/logging.
// Post Actions: Always notifies SNS when pipeline finishes.

pipeline {
    agent any
    options {
        disableConcurrentBuilds() // Prevents concurrent pipeline runs
    }
    environment {
        AWS_REGION = 'eu-central-1' // AWS region
        ECR_REPO_NAME = 'cloud-app' // ECR repository name
        ECR_ACCOUNT_ID = '<your-account-id>' // AWS account ID
        IMAGE_TAG  = "${BUILD_NUMBER}" // Tag for Docker image
        IMAGE_URI = "${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}:${BUILD_NUMBER}" // Full image URI
        CLUSTER_NAME = 'app-ecs-cluster' // ECS cluster name
        SERVICE_NAME = 'app-service' // ECS service name
        TASK_FAMILY = 'app-service'  // ECS task family
        S3_BUCKET = 'cloud-pipeline-logs' // S3 bucket for logs
        SNS_TOPIC_ARN = '<sns-topic-arn>' // SNS topic ARN for notifications
        APP_DOMAIN = 'app.example.com' // Application domain for health check
    }

    stages {
        stage('Build Docker Image') { // Build Docker image
            steps {
                sh 'docker build -t ${IMAGE_URI} .'
            }
        }

        stage('Push to ECR') { // Push image to AWS ECR
            steps {
                sh 'aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com'
                sh 'docker push ${IMAGE_URI}'
            }
        }

       stage('Deploy to ECS') { // Update ECS service with new image
            steps {
                script {
                    sh """
                    echo "Getting current task definition..."
                    TASK_DEF=\$(aws ecs describe-task-definition --task-definition $TASK_FAMILY)

                    echo "Creating updated task definition with new image..."
                    NEW_DEF=\$(echo "\$TASK_DEF" | jq --arg IMAGE_URI "$IMAGE_URI" '
                      .taskDefinition |
                      {
                        family,
                        executionRoleArn,
                        networkMode,
                        containerDefinitions,
                        requiresCompatibilities,
                        cpu,
                        memory
                      } |
                      .containerDefinitions[0].image = \$IMAGE_URI
                    ')

                    echo "\$NEW_DEF" > new-task-def.json

                    echo "Registering new task definition..."
                    aws ecs register-task-definition \
                      --cli-input-json file://new-task-def.json

                    NEW_REVISION=\$(aws ecs describe-task-definition --task-definition $TASK_FAMILY --query 'taskDefinition.revision' --output text)

                    echo "Updating service to use new revision..."
                    aws ecs update-service \
                      --cluster $CLUSTER_NAME \
                      --service $SERVICE_NAME \
                      --task-definition $TASK_FAMILY:\$NEW_REVISION

                    echo "Waiting for ECS service to stabilize..."
                    aws ecs wait services-stable \
                      --cluster $CLUSTER_NAME \
                      --services $SERVICE_NAME
                    """
                }
            }
        }

        stage('Verify Health') { // Run health check script
            steps {
                script {
                    sh """
                    chmod +x verify_health.sh
                    ./verify_health.sh "https://${APP_DOMAIN}"
                    """
                }
            }
        }

        stage('Notify SNS') { // Notify via SNS on success
            steps {
                sh 'aws sns publish --topic-arn ${SNS_TOPIC_ARN} --message "Pipeline completed successfully: Build #${BUILD_NUMBER}"'
            }
        }

        stage('Pipeline Logging') { // Upload Docker image list to S3
            steps {
                // FLAW: Excessive S3 logging inflates costs
                sh 'docker images | tee >(aws s3 cp - s3://${S3_BUCKET}/pipeline-${BUILD_NUMBER}.txt)'
            }
        }
    }

    post {
        always {
            script {
                // Always notify SNS when pipeline finishes
                sh 'aws sns publish --topic-arn ${SNS_TOPIC_ARN} --message "Pipeline finished: Build #${BUILD_NUMBER}"'
            }
        }
    }
}
