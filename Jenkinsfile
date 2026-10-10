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

                        docker push "$BACKEND_IMAGE:$BUILD_NUMBER"
			docker push "$FRONTEND_IMAGE:$BUILD_NUMBER"
                    '''
                }
            }
        }
	        stage('Terraform Deploy') {
            steps {
                timeout(time: 25, unit: 'MINUTES') {
                                        withCredentials([
                        string(
                            credentialsId: 'mysql-app-password',
                            variable: 'TF_VAR_mysql_password'
                        ),
                        string(
                            credentialsId: 'mysql-root-password',
                            variable: 'TF_VAR_mysql_root_password'
                        ),
                        string(
                            credentialsId: 'grafana-admin-password',
                            variable: 'TF_VAR_grafana_admin_password'
                        )
                    ]) {
                        dir('terraform') {
                            sh '''
                                set +x
                                set -eu
                                umask 077

                                export KUBECONFIG=/var/lib/jenkins/.kube/config
                                export TF_IN_AUTOMATION=true
                                export TF_VAR_backend_image="$BACKEND_IMAGE:$BUILD_NUMBER"
                                export TF_VAR_frontend_image="$FRONTEND_IMAGE:$BUILD_NUMBER"

                                terraform init -input=false -reconfigure
                                terraform fmt -check
                                terraform validate
                                terraform plan -input=false -out=deployment.tfplan
                                terraform apply -input=false deployment.tfplan

                                kubectl rollout status deployment/mysql -n devops --timeout=300s
                                kubectl rollout status deployment/backend -n devops --timeout=300s
                                kubectl rollout status deployment/frontend -n devops --timeout=300s
                                kubectl get pods -n devops
                            '''
                        }
                    }
                }
            }
            post {
                always {
                    sh 'rm -f terraform/deployment.tfplan'
                }
            }
        }
    }
}
