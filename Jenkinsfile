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
        ODC_VERSION     = "12.1.0"
    }

    stages {

        /* === 1. CLONAR TU REPOSITORIO === */
        stage('Checkout Código') {
            steps {
                git branch: 'main', url: 'https://github.com/AlanCar0/ciberseguirdad'
            }
        }

        /* === 2. DEPENDENCIAS PYTHON === */
        stage('Instalar Dependencias Python') {
            steps {
                sh '''
                pip install --upgrade pip
                pip install -r requirements.txt
                pip install pip-audit
                '''
            }
        }

        /* === 3. INSTALAR DEPENDENCY-CHECK === */
        stage('Instalar Dependency Check') {
            steps {
                sh '''
                apt-get update
                apt-get install -y openjdk-21-jre-headless wget unzip

                export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-arm64
                export PATH="$JAVA_HOME/bin:$PATH"

                mkdir -p /opt/dependency-check
                cd /opt/dependency-check

                wget https://github.com/jeremylong/DependencyCheck/releases/download/v$ODC_VERSION/dependency-check-$ODC_VERSION-release.zip
                unzip dependency-check-$ODC_VERSION-release.zip
                chmod +x dependency-check/bin/dependency-check.sh
                '''
            }
        }

        /* === 4. ANALISIS SCA - DEPENDENCY CHECK === */
stage('Dependency Check (SCA)') {
    steps {
        sh '''
        set +e
        /opt/dependency-check/dependency-check/bin/dependency-check.sh \
    --project vulnerable-app \
    --scan . \
    --out dependency-check-report \
    --disableAssembly \
    --nvdApiKey $NVD_API_KEY
        EXIT_CODE=$?
        if [ $EXIT_CODE -ne 0 ]; then
            echo "WARNING: Dependency-Check falló, continuando con pipeline..."
        fi
        set -e
        '''
    }
    post {
        always {
            publishHTML(target: [
                reportDir: 'dependency-check-report',
                reportFiles: 'dependency-check-report.html',
                reportName: 'Reporte SCA - DependencyCheck',
                allowMissing: true
            ])
        }
    }
}

        /* === 5. ANALISIS SCA (PYTHON) === */
        stage('pip-audit (SCA Python)') {
            steps {
                sh '''
                pip-audit -r requirements.txt -f json > audit.json
                '''
            }
            post {
                always {
                    archiveArtifacts 'audit.json'
                }
            }
        }

        /* === 6. SAST CON SONARQUBE === */
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

        /* === 7. DAST CON OWASP ZAP === */
        stage('DAST con ZAP') {
            steps {
                sh '''
                apt-get update
                apt-get install -y wget unzip openjdk-21-jre-headless

                echo "Iniciando tu app Flask vulnerable..."
                python vulnerable_app.py &

                sleep 10

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
                        reportName: 'Reporte DAST - ZAP',
                        allowMissing: true
                    ])
                }
            }
        }
    }
}
