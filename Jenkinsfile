pipeline {
    agent {
        node {
            label 'cloud_agent'
        }
    }
    tools {
        maven 'Maven3'
        jdk "openJDK"
    }

    environments {
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "172.31.62.34:8081" //Private_IP
        NEXUS_REPOSITORY = "vprofile-release"
        NEXUS_REPOGRP_ID    = "vprofile-maven-group"
        NEXUS_CREDENTIAL_ID = "nexuslogin"
        ARTVERSION = "${env.BUILD_ID}"
        scannerHome = tool 'sonarscanner6'
    }

    stages {
        stage('Fetch Source Code') {
            steps{
                git branch: 'main', url: 'https://github.com/goognecs/vproject.git'
            }
        }

        stage('Build') {
            steps{
                sh 'mvn install -DskipTests'
            }
            post {
                success {
                    echo "Now Archiving Artifact"
                    archiveArtifacts(artifacts: '**/target/*war')
                }
            }
        }
        stage('Unit Test') {
            steps{
                sh 'mvn test'
            }
        }
        stage('Integration Test') {
            steps{
                sh 'mvn verify -DskipUnitTests'
            }
        }

        stage ('CODE ANALYSIS WITH CHECKSTYLE'){
            steps {
                sh 'mvn checkstyle:checkstyle'
            }
            post {
                success {
                    echo 'Generated Analysis Result'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar-vprofile') {
                    sh '''${scannerHOme}/bin/sonar-scanner
                    -Dsonar.projectKey=vprofile \   # give the key name of your project#
                    -Dsonar.projectName='vprofile' \  # give the name of your project#
                    -Dsonar.sources=./src/ \
                    -Dsonar.tests=./src/test/java \
                    -Dsonar.java.binaries=./target/test-classes/com/visualpathit/account/controllerTest/ \
                    -Dsonar.junit.reportPaths=./target/surefire-reports \
                    -Dsonar.jacoco.reportPaths=./target/site/jacoco/jacoco.xml \
                    -Dsonar.checkstyle.reportPath=./target/checkstyle-result.xml"
                    '''
                }
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate(abortPipeline: true)
                }
            }
        }
        stage('Publish Artifacts to Nexus Repository') {
            steps {
                script {
                    pom = readMavenPom file: "pom.xml";
                    filesByGlob = findFiles(glob: "target/*.${pom.packaging}");
                    echo "${filesByGlob[0].name} ${filesByGlob[0].path} ${filesByGlob[0].directory} ${filesByGlob[0].length} ${filesByGlob[0].lastModified}"
                    artifactPath = filesByGlob[0].path;
                    artifactExists = fileExists artifactPath;
                    if(artifactExists) {
                        echo "*** File: ${artifactPath}, group: ${pom.groupId}, packaging: ${pom.packaging}, version ${pom.version} ARTVERSION";
                        nexusArtifactUploader(
                            nexusVersion: NEXUS_VERSION,
                            protocol: NEXUS_PROTOCOL,
                            nexusUrl: NEXUS_URL,
                            groupId: NEXUS_REPOGRP_ID,
                            version: ARTVERSION,
                            repository: NEXUS_REPOSITORY,
                            credentialsId: NEXUS_CREDENTIAL_ID,
                            artifacts: [
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: artifactPath,
                                type: pom.packaging],
                                [artifactId: pom.artifactId,
                                classifier: '',
                                file: "pom.xml",
                                type: "pom"]
                            ]
                        );
                    }
                }
            }
        }
    }
}
