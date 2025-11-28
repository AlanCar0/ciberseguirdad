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

        /* -------------------------------
         * 1) Checkout del código
         * ------------------------------- */
        stage('Checkout Código') {
            steps {
                git branch: 'main', url: 'https://github.com/AlanCar0/ciberseguirdad'
            }
        }

        /* -------------------------------
         * 2) Instalar dependencias Python
         * ------------------------------- */
        stage('Instalar Dependencias Python') {
            steps {
                sh '''
                pip install --upgrade pip
                pip install -r requirements.txt
                pip install pip-audit
                '''
            }
        }

        /* -------------------------------
         * 3) Instalar Dependency Check (requiere Java)
         * ------------------------------- */
        stage('Instalar Dependency Check') {
            steps {
                sh '''
                # Instalar Java 17
                apt-get update
                apt-get install -y openjdk-17-jre-headless wget unzip

                # Configurar JAVA_HOME
                export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
                export PATH=$JAVA_HOME/bin:$PATH
                echo "JAVA_HOME=$JAVA_HOME"

                # Instalar Dependency-Check CLI
                mkdir -p /opt/dependency-check
                cd /opt/dependency-check

                wget https://github.com/jeremylong/DependencyCheck/releases/download/v$ODC_VERSION/dependency-check-$ODC_VERSION-release.zip
                unzip dependency-check-$ODC_VERSION-release.zip

                chmod +x dependency-check/bin/dependency-check.sh
                '''
            }
        }

        /* -------------------------------
         * 4) Dependency Check (SCA)
         * ------------------------------- */
        stage('Dependency Check (SCA)') {
            steps {
                sh '''
                export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
                export PATH=$JAVA_HOME/bin:$PATH

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

        /* -------------------------------
         * 5) pip-audit (SCA Python)
         * ------------------------------- */
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

        /* -------------------------------
         * 6) SonarQube (SAST)
         * ------------------------------- */
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

        /* -------------------------------
         * 7) DAST con OWASP ZAP
         * ------------------------------- */
        stage('DAST con ZAP') {
            steps {
                sh '''
                # Instalar Java y herramientas necesarias para ZAP
                apt-get update && apt-get install -y wget unzip openjdk-17-jre-headless

                export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
                export PATH=$JAVA_HOME/bin:$PATH

                # Levantar el servidor Flask vulnerable
                python vulnerable_app.py &
                sleep 8

                # Descargar ZAP
                mkdir -p /opt/zap
                cd /opt/zap
                wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
                tar -xvf ZAP_2.15.0_Linux.tar.gz

                # Ejecutar ZAP Full Scan
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
