pipeline {
    agent any

    environment {
        IMAGE_NAME = "vulnerable-app"
        TARGET_URL = "http://host.docker.internal:5000"
        SONAR_SERVER = 'Sonar-Server'
    }

    stages {

        stage('1. Checkout') {
            steps {
                checkout scm
            }
        }

        stage('2. Setup Python Environment') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('3. Build & Unit Tests') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME} .
                    docker run --rm ${IMAGE_NAME} python3 -m unittest test_app.py
                """
            }
        }

        stage('4. Static Analysis (SonarQube)') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv("${SONAR_SERVER}") {
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.projectKey=ProyectoMacM3 \
                                -Dsonar.sources=. \
                                -Dsonar.host.url=http://host.docker.internal:9000 \
                                -Dsonar.login=${SONAR_AUTH_TOKEN}
                        """
                    }
                }
            }
        }

        stage('5. Dependency Check (SCA)') {
            steps {
                dependencyCheck additionalArguments: '--format HTML --format XML', odcInstallation: 'DP-Check'
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'Reporte SCA'
                    ])
                }
            }
        }

        stage('6. Start Vulnerable App (for DAST)') {
            steps {
                sh "docker run -d -p 5000:5000 --name app-target ${IMAGE_NAME}"
                sh "sleep 10"
            }
        }

        stage('7. OWASP ZAP DAST') {
            steps {
                sh """
                    docker run --add-host=host.docker.internal:host-gateway --rm \
                    zaproxy/zap-stable zap-baseline.py \
                    -t ${TARGET_URL} \
                    -r zap_report.html \
                    -I
                """
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'zap_report.html',
                        reportName: 'Reporte DAST'
                    ])
                }
            }
        }
    }

    post {
        always {
            sh "docker rm -f app-target || true"
        }
    }
}