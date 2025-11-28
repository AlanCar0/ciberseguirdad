pipeline {

    agent {
        docker {
            image 'python:3.12-slim'
            args '-u root:root'
        }
    }

    environment {
        SONARQUBE_TOKEN = credentials('SonarScannerQube')
        NVD_API_KEY     = credentials('nvdApiKey')
        TARGET_URL      = "http://127.0.0.1:5000"
        ODC_VERSION     = "10.0.3"
    }

    stages {

        stage('Checkout Código') {
            steps {
                git branch: 'main', url: 'https://github.com/AlanCar0/ciberseguirdad'
            }
        }

        stage('Instalar Dependencias Python') {
            steps {
                sh '''
                pip install --upgrade pip
                pip install -r requirements.txt
                pip install pip-audit
                '''
            }
        }

        stage('Instalar Dependency Check') {
            steps {
                sh '''
                mkdir -p /opt/dependency-check
                cd /opt/dependency-check

                apt-get update && apt-get install -y wget unzip

                wget https://github.com/jeremylong/DependencyCheck/releases/download/v$ODC_VERSION/dependency-check-$ODC_VERSION-release.zip

                unzip dependency-check-$ODC_VERSION-release.zip
                chmod +x dependency-check/bin/dependency-check.sh
                '''
            }
        }

        stage('Dependency Check (SCA)') {
            steps {
                sh '''
                /opt/dependency-check/dependency-check/bin/dependency-check.sh \
                    --project vulnerable-app \
                    --scan . \
                    --nvdApiKey $NVD_API_KEY \
                    --out dependency-check-report
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: 'dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'Dependency Security Report',
                        allowMissing: true
                    ])
                }
            }
        }

        stage('pip-audit (SCA python)') {
            steps {
                sh '''
                pip-audit -r requirements.txt -f json > audit.json
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'audit.json'
                }
            }
        }

        stage('SonarQube (SAST)') {
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

        stage('DAST con ZAP') {
            steps {
                sh '''
                echo "Instalando dependencias para ZAP..."
                apt-get update && apt-get install -y wget unzip openjdk-17-jre

                echo "Iniciando servidor Flask..."
                python vulnerable_app.py &

                sleep 8

                echo "Descargando ZAP..."
                mkdir -p /opt/zap
                cd /opt/zap
                wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
                tar -xvf ZAP_2.15.0_Linux.tar.gz

                /opt/zap/ZAP_2.15.0/zap.sh \
                    -cmd \
                    -quickurl $TARGET_URL \
                    -quickout zap-report.html
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: '.',
                        reportFiles: 'zap-report.html',
                        reportName: 'OWASP ZAP DAST Report',
                        allowMissing: false
                    ])
                }
            }
        }
    }
}
