pipeline {
    agent any

    tools {
        jdk 'JAVA_HOME'
        maven 'M2_HOME'
    }

    options {
        skipDefaultCheckout(true)
        disableConcurrentBuilds()
    }

    environment {
        BACKEND_IMAGE = 'saifgharbi/gharbisaif_5arctic8_gestionprojets-backend'
        FRONTEND_IMAGE = 'saifgharbi/gharbisaif_5arctic8_gestionprojets-frontend'
    }

    stages {
        stage('GIT') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/SaifGharbi/5ArcTic8-SaifGharbi.git'
            }
        }

        stage('Build') {
            steps {
                dir('backend') {
                    sh 'mvn -B clean compile'
                }
            }
        }

                stage('Tests') {
            steps {
                dir('backend') {
                    sh 'mvn -B test'
                    sh 'test -s target/site/jacoco/jacoco.xml'
                }
            }
            post {
                always {
                    junit testResults: 'backend/target/surefire-reports/*.xml',
                          allowEmptyResults: false
                }
                success {
                    archiveArtifacts artifacts: 'backend/target/site/jacoco/**',
                                     fingerprint: true
                }
            }
        }

        stage('SonarQube') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        withEnv(["SONAR_TOKEN=${env.SONAR_AUTH_TOKEN}"]) {
			 sh(
                                'mvn -B ' +
                                'org.sonarsource.scanner.maven:' +
                                'sonar-maven-plugin:5.8.0.7211:sonar ' +
                                '-Dsonar.projectKey=Devops-project ' +
                                '-Dsonar.projectName=Devops-project ' +
                                '-Dsonar.coverage.jacoco.xmlReportPaths=' +
                                'target/site/jacoco/jacoco.xml'
                            )
                        }
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        def gate = waitForQualityGate()

                        if (gate.status != 'OK') {
                            error "Quality Gate failed: ${gate.status}"
                        }
                    }
                }
            }
        }

        stage('Package') {
            steps {
                dir('backend') {
                    sh 'mvn -B package -DskipTests'
                }

                archiveArtifacts artifacts: 'backend/target/*.jar',
                                 fingerprint: true
            }
        }

        stage('Backend Docker Build') {
            steps {
                sh 'docker build -t "$BACKEND_IMAGE:$BUILD_NUMBER" backend'
            }
        }

        stage('Frontend Docker Build') {
            steps {
                sh 'docker build -t "$FRONTEND_IMAGE:$BUILD_NUMBER" frontend'
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKERHUB_USER',
                    passwordVariable: 'DOCKERHUB_TOKEN'
                )]) {
                    sh '''
                        set +x
                        export DOCKER_CONFIG="$(mktemp -d)"
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT

                        printf '%s' "$DOCKERHUB_TOKEN" |
                          docker login \
                            --username "$DOCKERHUB_USER" \
                            --password-stdin

                        docker push "$DOCKER_IMAGE:$BUILD_NUMBER"
                    '''
                }
            }
        }
    }
}
