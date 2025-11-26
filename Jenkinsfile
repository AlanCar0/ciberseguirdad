pipeline {
    agent any

    environment {
        IMAGE_NAME = "parcial3-app"
        // Configuración para Mac M3: usamos host.docker.internal para redes
        TARGET_URL = "http://host.docker.internal:5000" 
    }

    stages {
        stage('1. Checkout & Trazabilidad') {
            steps {
                echo "Iniciando Pipeline del Parcial 3..."
                checkout scm
                // Esto cumple con el punto de documentación y trazabilidad del PDF
                sh 'echo "Commit actual: $(git rev-parse HEAD)"'
            }
        }

        stage('2. Build de la Aplicación') {
            steps {
                echo "Construyendo imagen Docker..."
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('3. Unit Tests (Calidad)') {
            steps {
                echo "Ejecutando pruebas unitarias..."
                // Ejecutamos los tests dentro del contenedor
                sh "docker run --rm ${IMAGE_NAME} python -m unittest test_app.py"
            }
        }

        stage('4. Análisis de Dependencias (SCA)') {
            steps {
                echo "Analizando vulnerabilidades en librerías (OWASP Dependency-Check)..."
                // IMPORTANTE: Debes tener configurada la herramienta 'DP-Check' en Jenkins
                dependencyCheck additionalArguments: '--format HTML --format XML', odcInstallation: 'DP-Check'
            }
            post {
                always {
                    publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '', reportFiles: 'dependency-check-report.html', reportName: 'Reporte Dependencias'])
                }
            }
        }

        stage('5. Despliegue Temporal (Para DAST)') {
            steps {
                echo "Levantando entorno de pruebas..."
                // Ejecutamos la app en segundo plano (-d)
                sh "docker run -d -p 5000:5000 --name app-parcial ${IMAGE_NAME}"
                sh "sleep 10" // Espera para que arranque Flask
            }
        }

        stage('6. Análisis Dinámico de Seguridad (OWASP ZAP)') {
            steps {
                echo "Ejecutando ataque controlado con ZAP..."
                // Usamos la imagen compatible con Mac M3 (zaproxy/zap-stable)
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
                    publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '.', reportFiles: 'zap_report.html', reportName: 'Reporte Seguridad ZAP'])
                }
            }
        }
    }

    post {
        always {
            echo "Limpiando entorno..."
            // Eliminamos el contenedor para no dejar basura (Gestión de recursos)
            sh "docker rm -f app-parcial || true"
        }
        success {
            echo "Pipeline Exitoso. Cumple con criterios del Parcial."
        }
        failure {
            echo "Pipeline Fallido. Revisar logs."
        }
    }
}
