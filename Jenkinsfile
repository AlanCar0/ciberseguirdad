pipeline {
    agent any

    environment {
        // En Mac usamos host.docker.internal para que el contenedor vea al host
        SONARQUBE = 'Sonar-Server' 
        TARGET_URL = "http://host.docker.internal:8081/" 
    }

    stages {
        stage('Checkout') {
            steps {
                echo "Descargando código..."
                // checkout scm  <-- Esto se descomenta cuando tengas un Git real
            }
        }

        stage('Build') {
            steps {
                echo "Compilando..."
                // Simulamos la compilación creando una carpeta
                sh 'mkdir -p build && echo "Build OK" > build/result.txt'
            }
        }

        stage('SonarQube Analysis') {
            environment {
                // Debe coincidir con el nombre de la herramienta configurada en Jenkins -> Global Tool Configuration
                scannerHome = tool 'SonarScanner'
            }
            steps {
                // 'Sonar-Server' debe coincidir con el nombre en Manage Jenkins -> System
                withSonarQubeEnv('Sonar-Server') {
                    sh """
                    ${scannerHome}/bin/sonar-scanner \
                    -Dsonar.projectKey=MiProyectoMac \
                    -Dsonar.sources=. \
                    -Dsonar.host.url=http://host.docker.internal:9000
                    """
                }
            }
        }

        stage('OWASP Dependency-Check') {
            steps {
                echo "Analizando dependencias..."
                // Requiere haber instalado el plugin 'OWASP Dependency-Check' en Jenkins y configurado la herramienta
                dependencyCheck additionalArguments: '--format HTML --format XML', odcInstallation: 'DP-Check'
            }
            post {
                always {
                    publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '', reportFiles: 'dependency-check-report.html', reportName: 'Dependency-Check'])
                }
            }
        }

        stage('OWASP ZAP (DAST)') {
            steps {
                echo "Iniciando escaneo dinámico (DAST) con ZAP..."
                // Aquí usamos la imagen corregida para Mac M3
                sh '''
                docker run --add-host=host.docker.internal:host-gateway --rm \
                zaproxy/zap-stable zap-baseline.py \
                -t http://host.docker.internal:8081/ \
                -r zap_report.html
                '''
            }
            post {
                always {
                    publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, keepAll: true, reportDir: '.', reportFiles: 'zap_report.html', reportName: 'ZAP Security Report'])
                }
            }
        }
    }
}
