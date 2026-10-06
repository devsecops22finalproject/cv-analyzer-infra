pipeline {
  agent any
  environment {
    DOCKERHUB_USER = credentials('dockerhub-user')
    AI_MODEL = 'muse-spark-1.3-contributor'
    MUSE_SPARK_BASE_URL = credentials('muse-spark-base-url')
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Lint') {
      steps {
        sh 'flake8 app/backend/ || true'
        sh 'cd app/frontend && npm run build'
      }
    }
    stage('Unit Tests') {
      steps {
        sh 'cd app/backend && MOCK_AI=1 pytest -q'
        sh 'cd app/frontend && npm test -- --watchAll=false || true'
      }
    }
    stage('Docker Build') {
      steps {
        sh 'docker build -t $DOCKERHUB_USER/job-screener-backend:${BUILD_NUMBER} -t $DOCKERHUB_USER/job-screener-backend:latest app/backend'
        sh 'docker build -t $DOCKERHUB_USER/job-screener-frontend:${BUILD_NUMBER} -t $DOCKERHUB_USER/job-screener-frontend:latest app/frontend'
      }
    }
    stage('Push Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker-hub-creds', usernameVariable: 'U', passwordVariable: 'P')]) {
          sh 'echo $P | docker login -u $U --password-stdin && docker push $DOCKERHUB_USER/job-screener-backend:${BUILD_NUMBER} && docker push $DOCKERHUB_USER/job-screener-backend:latest && docker push $DOCKERHUB_USER/job-screener-frontend:${BUILD_NUMBER} && docker push $DOCKERHUB_USER/job-screener-frontend:latest'
        }
      }
    }
    stage('Deploy K8s') {
      steps {
        withCredentials([file(credentialsId: 'kube-config', variable: 'KUBECONFIG')]) {
          sh 'kubectl set image deployment/backend backend=$DOCKERHUB_USER/job-screener-backend:${BUILD_NUMBER} -n job-screener && kubectl set image deployment/frontend frontend=$DOCKERHUB_USER/job-screener-frontend:${BUILD_NUMBER} -n job-screener && kubectl rollout status deployment/backend -n job-screener && kubectl rollout status deployment/frontend -n job-screener'
        }
      }
    }
    stage('Health/API Test') {
      steps {
        withCredentials([string(credentialsId: 'muse-spark-key', variable: 'MUSE_SPARK_API_KEY')]) {
          sh 'bash devops/scripts/smoke.sh http://backend:5000'
        }
      }
    }
  }
}
