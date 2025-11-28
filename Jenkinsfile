pipeline {

    agent none   // declaramos none para usar distintos contenedores

    environment {
        SONARQUBE_TOKEN = credentials('SonarScannerQube')
        NVD_API_KEY     = credentials('nvdApiKey')
        TARGET_URL      = "http://127.0.0.1:5000"
    }

    stages {

        /* ---------- CHECKOUT ---------- */
        stage('Checkout Código') {
            agent { docker { image 'python:3.10-bullseye' } }
            steps {
                git branch: 'main', url: 'https://github.com/AlanCar0/ciberseguirdad'
            }
        }

        /* ---------- DEPENDENCIAS PYTHON ---------- */
        stage('Instalar Dependencias Python') {
            agent { docker { image 'python:3.10-bullseye' } }
            steps {
                sh '''
                pip install --upgrade pip
                pip install -r requirements.txt
                pip install pip-audit
                '''
            }
        }

        /* ---------- DEPENDENCY CHECK (IMAGEN OFICIAL) ---------- */
        stage('Dependency-Check') {
            agent {
                docker {
                    image 'owasp/dependency-check:latest'
                    args "-v ${WORKSPACE}:/src"      // monta tu proyecto dentro del contenedor
                }
            }
            steps {
                sh '''
                dependency-check.sh \
                    --project vulnerable-app \
                    --scan /src \
                    --nvdApiKey $NVD_API_KEY \
                    --out /src/dependency-check-report \
                    --format HTML
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: 'dependency-check-report',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'Dependency Security Report',
                        allowMissing: true,
                        keepAll: true
                    ])
                }
            }
        }

        /* ---------- PIP AUDIT ---------- */
        stage('pip-audit') {
            agent { docker { image 'python:3.10-bullseye' } }
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

        /* ---------- SONARQUBE ---------- */
        stage('SonarQube Scanner') {
            agent { docker { image 'sonarsource/sonar-scanner-cli:latest' } }
            steps {
                withSonarQubeEnv('SonarQubeScanner') {
                    sh """
                    sonar-scanner \
                        -Dsonar.projectKey=vulnerable-app \
                        -Dsonar.sources=/usr/src \
                        -Dsonar.host.url=http://sonarqube:9000 \
                        -Dsonar.login=$SONARQUBE_TOKEN
                    """
                }
            }
        }

        /* ---------- OWASP ZAP ---------- */
        stage('OWASP ZAP DAST Scan') {
            agent { docker { image 'python:3.10-bullseye' } }
            steps {
                sh '''
                echo "Levantando servidor Flask..."
                python vulnerable_app.py &

                echo "Esperando que Flask levante..."
                sleep 8

                apt-get update && apt-get install -y wget unzip openjdk-17-jre

                echo "Descargando ZAP..."
                mkdir -p /opt/zap
                cd /opt/zap

                wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
                tar -xvf ZAP_2.15.0_Linux.tar.gz

                echo "Corriendo escaneo ZAP..."
                /opt/zap/ZAP_2.15.0/zap.sh \
                    -cmd \
                    -quickurl $TARGET_URL \
                    -quickout $WORKSPACE/zap-report.html
                '''
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: '.',
                        reportFiles: 'zap-report.html',
                        reportName: 'OWASP ZAP DAST Report'
                    ])
                }
            }
        }
    }
}
