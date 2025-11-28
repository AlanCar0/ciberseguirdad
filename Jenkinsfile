pipeline {
    agent any

    environment {
        SONARQUBE_TOKEN = credentials('SonarScannerQube')
        NVD_API_KEY     = credentials('nvdApiKey')
        TARGET_URL      = "http://127.0.0.1:5000"
        ODC_VERSION     = "10.0.3"
    }

    stages {

        stage("Checkout Código") {
            steps {
                git branch: 'main', url: 'https://github.com/AlanCar0/ciberseguirdad'
            }
        }

        stage("Instalar dependencias (Python)") {
            steps {
                sh """
                pip install --upgrade pip
                pip install -r requirements.txt
                pip install pip-audit
                """
            }
        }

        stage("Instalar Dependency Check") {
            steps {
                sh """
                mkdir -p dependency-check
                cd dependency-check

                wget https://github.com/jeremylong/DependencyCheck/releases/download/v$ODC_VERSION/dependency-check-$ODC_VERSION-release.zip
                apt-get update && apt-get install -y unzip
                unzip dependency-check-$ODC_VERSION-release.zip

                chmod +x dependency-check/bin/dependency-check.sh
                """
            }
        }

        stage("Dependency Check (SCA)") {
            steps {
                sh """
                dependency-check/dependency-check/bin/dependency-check.sh \
                    --project vulnerable-app \
                    --scan . \
                    --nvdApiKey $NVD_API_KEY \
                    --out dependency-check-report
                """
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: "dependency-check-report",
                        reportFiles: "dependency-check-report.html",
                        reportName: "Reporte SCA",
                        allowMissing: true,
                        keepAll: true,
                        alwaysLinkToLastBuild: true
                    ])
                }
            }
        }

        stage("pip-audit (SCA python)") {
            steps {
                sh """
                pip-audit -r requirements.txt -f json > audit.json
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: "audit.json"
                }
            }
        }

        stage("SonarQube (SAST)") {
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

        stage("DAST con ZAP") {
            steps {
                sh """
                echo "Levantando aplicación vulnerable..."
                python vulnerable_app.py &
                sleep 9

                echo "Instalando ZAP..."
                apt-get update && apt-get install -y wget openjdk-17-jre

                mkdir -p zap
                cd zap
                wget https://github.com/zaproxy/zaproxy/releases/download/v2.15.0/ZAP_2.15.0_Linux.tar.gz
                tar -xvf ZAP_2.15.0_Linux.tar.gz

                echo "Ejecutando DAST..."
                zap/ZAP_2.15.0/zap.sh \
                    -cmd \
                    -quickurl $TARGET_URL \
                    -quickout ../zap-report.html
                """
            }
            post {
                always {
                    publishHTML(target: [
                        reportDir: ".",
                        reportFiles: "zap-report.html",
                        reportName: "Reporte DAST",
                        allowMissing: true,
                        keepAll: true,
                        alwaysLinkToLastBuild: true
                    ])
                }
            }
        }
    }
}
