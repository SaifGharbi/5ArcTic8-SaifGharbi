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
                }
            }
            post {
                always {
                    junit testResults: 'backend/target/surefire-reports/*.xml',
                          allowEmptyResults: true
                }
            }
        }

        stage('SonarQube') {
            steps {
                dir('backend') {
                    withSonarQubeEnv('SonarQube') {
                        withEnv(["SONAR_TOKEN=${env.SONAR_AUTH_TOKEN}"]) {
                            sh '''
                                mvn -B org.sonarsource.scanner.maven:sonar-maven-plugin:sonar \
                                  -Dsonar.projectKey=Devops-project \
                                  -Dsonar.projectName=Devops-project
                            '''
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
    }
}

