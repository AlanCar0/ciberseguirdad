pipeline {
    agent any

    environment {
        IMAGE_NAME = "vulnerable-app"
        // Si estás en WSL/Windows, host.docker.internal permite al contenedor ver al host
        TARGET_URL = "http://host.docker.internal:5000" 
        SONAR_SERVER = 'Sonar-Server' // Asegúrate de que este nombre coincida con tu config en Jenkins
        SCANNER_HOME = tool 'SonarScanner'
    }

    stages {
        stage('1. Checkout') {
            steps {
                checkout scm
            }
        }

        stage('2. Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_NAME} ."
                }
            }
        }

        stage('3. Unit Tests (Python)') {
            steps {
                // Ejecuta los tests dentro del contenedor y luego lo elimina
                sh "docker run --rm ${IMAGE_NAME} python -m unittest test_app.py"
            }
        }

        stage('4. SCA - Dependency Check') {
            steps {
                // Requisito: Gestión de dependencias
                dependencyCheck additionalArguments: '--format HTML --format XML --out .', odpInstallation: 'Dependency-Check'
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'dependency-check-report.html',
                        reportName: 'Reporte SCA (Dependencias)'
                    ])
                }
            }
        }

        stage('5. SAST - SonarQube Analysis') {
            steps {
                withSonarQubeEnv("${SONAR_SERVER}") {
                    sh """
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=VulnerableApp_Examen \
                        -Dsonar.sources=. \
                        -Dsonar.python.version=3.9 \
                        -Dsonar.host.url=http://host.docker.internal:9000 \
                        -Dsonar.login=\${SONAR_AUTH_TOKEN}
                    """
                }
            }
        }

        stage('6. Start App for DAST') {
            steps {
                // Levantamos la app en segundo plano para atacarla con ZAP
                sh "docker run -d -p 5000:5000 --name app-target ${IMAGE_NAME}"
                // Esperamos unos segundos a que inicie Flask
                sh "sleep 10"
            }
        }

        stage('7. DAST - OWASP ZAP') {
            steps {
                // Ejecutamos el escaneo de ZAP contra la app levantada
                // Usamos || true para que el pipeline no falle si encuentra alertas (queremos el reporte)
                sh """
                    docker run --add-host=host.docker.internal:host-gateway --rm \
                    zaproxy/zap-stable zap-baseline.py \
                    -t ${TARGET_URL} \
                    -r zap_report.html \
                    -I || true
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
                        reportName: 'Reporte DAST (OWASP ZAP)'
                    ])
                }
            }
        }
    }

    post {
        always {
            // Limpieza: detener y borrar el contenedor de la app
            sh "docker rm -f app-target || true"
            cleanWs()
        }
    }
}