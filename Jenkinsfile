pipeline {
    agent any

    environment {
        // Nombre de la imagen temporal de tu app
        IMAGE_NAME = "mi-app-segura"
        // URL objetivo: Usamos host.docker.internal para salir del contenedor de ZAP al host
        // O si usas la red docker: http://app-target:5000
        TARGET_URL = "[http://host.docker.internal:5000](http://host.docker.internal:5000)" 
        
        // Credencial de SonarQube configurada en Jenkins System
        SONAR_SERVER = 'Sonar-Server'
    }

    stages {
        stage('1. Checkout') {
            steps {
                echo "Descargando código del repositorio..."
                checkout scm
            }
        }

        stage('2. Build & Unit Tests') {
            steps {
                echo "Construyendo imagen y ejecutando tests..."
                // Construye la imagen
                sh "docker build -t ${IMAGE_NAME} ."
                // Corre los tests unitarios dentro del contenedor
                sh "docker run --rm ${IMAGE_NAME} python -m unittest test_app.py"
            }
        }

        stage('3. Análisis Estático (SonarQube)') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('Sonar-Server') {
                        sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=ProyectoMacM3 \
                        -Dsonar.sources=. \
                        -Dsonar.host.url=[http://host.docker.internal:9000](http://host.docker.internal:9000) \
                        -Dsonar.login=\${SONAR_AUTH_TOKEN}
                        """
                    }
                }
            }
        }

        stage('4. Análisis de Dependencias (SCA)') {
            steps {
                echo "Buscando librerías vulnerables..."
                dependencyCheck additionalArguments: '--format HTML --format XML', odcInstallation: 'DP-Check'
            }
            post {
                always {
                    publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '', reportFiles: 'dependency-check-report.html', reportName: 'Reporte SCA (Dependencias)'])
                }
            }
        }

        stage('5. Despliegue Temporal (Para DAST)') {
            steps {
                // Levantamos la app en segundo plano para atacarla
                sh "docker run -d -p 5000:5000 --name app-target ${IMAGE_NAME}"
                sh "sleep 10" // Esperar a que inicie
            }
        }

        stage('6. Análisis Dinámico (OWASP ZAP)') {
            steps {
                echo "Ejecutando escaneo de seguridad DAST..."
                // Usamos la imagen corregida para Mac (zaproxy/zap-stable)
                // host.docker.internal permite ver el puerto 5000 de tu Mac
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
                    publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '.', reportFiles: 'zap_report.html', reportName: 'Reporte DAST (ZAP)'])
                }
            }
        }
    }

    post {
        always {
            echo "Limpieza final..."
            // Borramos el contenedor de la app para no dejar basura
            sh "docker rm -f app-target || true"
        }
    }
}
