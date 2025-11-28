pipeline {
    agent any

    environment {
        SONARQUBE_TOKEN = credentials('sonarQubeToken')
        NVD_API_KEY     = credentials('nvdApiKey')
        TARGET_URL      = "http://localhost:8080"   // IMPORTANTE!
    }

    stages {

        stage('Checkout Código') {
            steps {
                git branch: 'main', url: 'https://github.com/AlanCar0/ciberseguirdad'
            }
        }

        stage('Instalar Python + dependencias') {
            steps {
                sh '''
                python3 -m venv .venv
                source .venv/bin/activate
                pip install -r requirements.txt
                pip install pip-audit
                '''
            }
        }

        // 🔥 ANÁLISIS DE SEGURIDAD
        stage('Dependency-Check') {
            steps {
                sh '''
                dependency-check.sh \
                --project vulnerable-app \
                --scan . \
                --nvdApiKey $NVD_API_KEY \
                --out dependency-check-report
                '''
            }
            post {
                success {
                    publishHTML([
                        reportDir: 'dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'Dependency Security Report'
                    ])
                }
            }
        }

        // 🧬 Auditoría Seguridad PIP
        stage('pip-audit') {
            steps {
                sh '''
                source .venv/bin/activate
                pip-audit -r requirements.txt -f json > audit.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'audit.json'
                }
            }
        }


        // 📡 Análisis SAST con SonarQube
        stage('SonarQube Scanner') {
            steps {
                withSonarQubeEnv('SonarQubeScanner') {
                    sh """
                    sonar-scanner \
                    -Dsonar.projectKey=vulnerable-app \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://sonarqube:9000 \
                    -Dsonar.login=$SONARQUBE_TOKEN
                    """
                }
            }
        }
    }
}
