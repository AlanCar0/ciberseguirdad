pipeline {

    agent {
        docker {
            image 'python:3.10-bullseye'
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

        stage('Instalar Dependency-Check') {
            steps {
                sh '''
                mkdir -p /opt/dependency-check
                cd /opt/dependency-check

                wget https://github.com/jeremylong/DependencyCheck/releases/download/v$ODC_VERSION/dependency-check-$ODC_VERSION-release.zip
                apt-get update && apt-get install -y unzip
                unzip dependency-check-$ODC_VERSION-release.zip
                chmod +x dependency-check/bin/dependency-check.sh
                '''
            }
        }

        stage('Dependency-Check') {
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
                        allowMissing: true,
                        keepAll: true,
                        alwaysLinkToLastBuild: true
                    ])
                }
            }
        }

        stage('pip-audit') {
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


        /*                  ZAP                    */
  
        stage('OWASP ZAP DAST Scan') {
            steps {
                sh '''
                echo "Iniciando servidor Flask..."
                python vulnerable_app.py &

                echo "Esperando a que el servidor levante..."
                sleep 8

                echo "Descargando OWASP ZAP..."
                apt-get update && apt-get install -y wget unzip openjdk-17-jre

                mkdir -p /opt/zap
                cd /opt/zap

                wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
                tar -xvf ZAP_2.15.0_Linux.tar.gz

                echo "Ejecutando ZAP CLI Full Scan..."
                /opt/zap/ZAP_2.15.0/zap.sh \
                    -cmd \
                    -quickurl $TARGET_URL \
                    -quickout /var/jenkins_home/workspace/Pipeline-test/zap-report.html
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: '.',
                        reportFiles: 'zap-report.html',
                        reportName: 'OWASP ZAP DAST Report',
                        allowMissing: false,
                        keepAll: true,
                        alwaysLinkToLastBuild: true
                    ])
                }
            }
        }
    }
}
