#!/usr/bin/env groovy

def lib = [:]
def image = [:]
deploymentId = [:]
def provisionOutput
def provisionBuild
def jenkinsWorkerPublicIP
def provisionFlag = false
imageTAG = 'develop'
provisionJob = "./delivery-tracker-${env.environment}-provision"

def initialization() {
  switch(env.environment) {
    case "prd":
      testEndpoint = 'https://test.deliverytracker.io/'
      break
    default:
      testEndpoint = "https://test.${env.environment}.deliverytracker.io/"
      break
  }

  imageTAG = DOCKER_TAG
}

pipeline {
  agent { node { label jenkinsNode } }
  options {
    timestamps ()
    ansiColor('xterm')
  }
  environment {
    NEWRELIC_CREDS = credentials("newrelic-${env.environment}-api")
    DOCKERHUB_CREDS = credentials('dockerhub-publish')
    DOCKER_BUILDKIT = '1'
  }
  stages {

    stage("Prepare build environment") {
      steps {
        script {
          // Load libraries
          lib['deployment'] = load 'jenkins/library/deployment.groovy'
          lib['slack'] = load 'jenkins/library/slack.groovy'
          lib['newrelic'] = load 'jenkins/library/newrelic.groovy'

          initialization()
          sh 'git --version'
          sh 'docker --version'
          sh 'docker login --username "${DOCKERHUB_CREDS_USR}" --password "${DOCKERHUB_CREDS_PSW}"'
          image['build'] = docker.image('node:12.13.0-slim')

          image['build'].inside() {
            sh 'node --version'
            sh 'npm --version'
            sh 'npm ci --verbose'
          }
        }
      }
    }

    stage("Provisioning environment") {
      steps {
        script {
          // Get the jenkins public IP
          jenkinsWorkerPublicIP = sh(script: "curl http://169.254.169.254/latest/meta-data/public-ipv4", returnStdout: true).trim()
        }
        script {
          echo "Will provision to ${env.environment} environment."
          
          provisionBuild = build job: "${provisionJob}", parameters: [ 
            string(name: 'TF_VAR_app_image_frontend', value: "metapackltd/delivery-tracker-frontend:${imageTAG}"),

            string(name: 'BRANCH', value: "${env.GIT_BRANCH}"),
            string(name: 'TF_VAR_jenkins_public_ip', value: "${jenkinsWorkerPublicIP}")
          ]
        }
        copyArtifacts(projectName: "${provisionJob}", selector: specific("${provisionBuild.number}"));
        script {
          provisionOutput = readJSON file: "${env.WORKSPACE}/provisioning/mf-output.json"
        }
      }
    }


    stage("Push static files") {
      parallel {

        stage('frontend') {
          steps {
            script {
              dir('apps/delivery-radar') {
                sh "rm -rf ./_collected-static/* || true"
                sh "docker rm dt-frontend | true"
                sh "docker container create --name dt-frontend metapackltd/delivery-tracker-frontend:${imageTAG}"
                sh "docker cp dt-frontend:/delivery-tracker/apps/delivery-radar/_collected-static/ ."
                image['aws'].inside() {
                  withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.jenkinsUserCred}"]]) {
                    sh """
                      aws --region ${provisionOutput.aws_region.value} s3 cp ./_collected-static s3://${env.environment}-${provisionOutput.aws_region.value}-delivery-tracker-tbd-shd-static/frontend --recursive
                    """
                  }
                }
                sh "docker rm dt-frontend"

                image['aws'].inside() {
                  withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.jenkinsUserCred}"]]) {
                    def statusCode = sh(script: """
                      cat /dev/null>cdn_invalidation.txt
                      echo "Clean old releases."
                      FRONTEND_ACTIVE_RELEASE=\$(curl -s https://${provisionOutput.endpoint_delivery_tracker.value}/ | grep -E '<!--build_hash.*-->\$' | sed -e 's/<!--build_hash:\\(.*\\)-->/\\1/')
                      if [ -z "\$FRONTEND_ACTIVE_RELEASE" ]; then
                        echo "Static release NOT detected."
                        exit 89
                      else
                        echo "Static release detected \$FRONTEND_ACTIVE_RELEASE."
                      fi
                      aws --region ${provisionOutput.aws_region.value} s3 ls s3://${env.environment}-${provisionOutput.aws_region.value}-delivery-tracker-tbd-shd-static/frontend/ --recursive | grep index.html | grep -v \$FRONTEND_ACTIVE_RELEASE | sort -r | tail -n +3 | while read -r line;
                          do
                            dirname=\$(echo \$line | awk {'print \$4'} | cut -d "/" -f 1,2)
                            echo "Deleting \$dirname directory."
                            aws --region ${provisionOutput.aws_region.value} s3 rm "s3://${env.environment}-${provisionOutput.aws_region.value}-delivery-tracker-tbd-shd-static/\$dirname" --recursive
                            echo "\${dirname}">>cdn_invalidation.txt
                          done
                      cat cdn_invalidation.txt
                    """, returnStatus:true)
                    if (statusCode == 89) {
                      currentBuild.result = 'UNSTABLE'
                    }
                  }                  
                }
              }

              image['akamai'].inside() {
                sh """
                    while read p; do
                      akamai purge --edgerc .edgerc invalidate --production "https://${provisionOutput.endpoint_static_content.value}/\$p/*"
                    done <apps/delivery-radar/cdn_invalidation.txt
                  """
              }
            }
          }
        }



        stage('common') {
          steps {
            script {
              dir('apps/_common') {
                image['aws'].inside() {
                  withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.jenkinsUserCred}"]]) {
                    sh """
                      aws --region ${provisionOutput.aws_region.value} s3 cp ./ s3://${env.environment}-${provisionOutput.aws_region.value}-delivery-tracker-tbd-shd-static/common --recursive
                    """
                  }
                }
              }

              image['akamai'].inside() {
                sh """
                  akamai purge --edgerc .edgerc invalidate --production "https://${provisionOutput.endpoint_static_content.value}/common/*"
                """
              }
            }
          }
        }

      }
    }

    stage("Deploying") {
      parallel {
        stage('frontend') {
          steps {

              script {
                dir('provisioning/templates') {
                  image['aws'].inside() {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.jenkinsUserCred}"]]) {
                      
                      lib['deployment'].clean(provisionOutput.aws_region.value, 
                                      provisionOutput.codedeploy_app_name.value, 
                                      provisionOutput.codedeploy_group_frontend.value)

                      deploymentId['frontend'] = lib['deployment'].start(provisionOutput.aws_region.value,
                                                                  provisionOutput.codedeploy_app_name.value, 
                                                                  provisionOutput.codedeploy_group_frontend.value, 
                                                                  provisionOutput.ecs_task_definition_frontend_arn.value)

                      lib['deployment'].wait(provisionOutput.aws_region.value, 
                                      provisionOutput.ecs_cluster_name.value, 
                                      provisionOutput.ecs_service_frontend_name.value, 
                                      deploymentId['frontend'])
  
                    }
                  }
                }
              }
            
          }
        }



    stage('Lighthouse') {
      steps {
        script {
          image['tests'] = docker.image('metapackltd/delivery-tracker-e2e:latest')

          image['tests'].inside() {
            sh 'node --version'
            dir('apps/delivery-radar') {
              sh "pwd ; ls -la ."
              sh "LIGHTHOUSE_URL=\"${testEndpoint}\" npm run lighthouse"
            }
          }
        }
      }
    }

    stage('NewRelic: Notify deployment') {
      steps {
        script {
          def builders = [:]
          ['frontend','tracking-api','admin','config-api','sentiment-api'].each {
            app -> builders[app] = {
              lib['newrelic'].notify(app, env.GIT_COMMIT)
            }
          }
          parallel builders
        }
      }
    }

  }
  post {
    always {
      archiveArtifacts artifacts: 'apps/delivery-radar/report.html', onlyIfSuccessful: true
      archiveArtifacts artifacts: 'apps/delivery-radar/cypress/screenshots/**/*.png', allowEmptyArchive: true
    }
    success {
      script {
        lib['slack'].notify('#00FF00', 'This build was terminated with success.')
      }
    }
    failure {
      // In case of unhealthy deployment      
      script {
        lib['slack'].notify('#FF0000', '@here This build was failed!!!')
        
        if ( provisionFlag ) {
          echo "Will stop the deployment and rollback to previous version on ${env.environment} environment."

          dir('provisioning') {
            image['aws'].inside() {
              withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${env.jenkinsUserCred}"]]) {
                sh "aws --region ${provisionOutput.aws_region.value} deploy stop-deployment --deployment-id '${deploymentId['frontend']}' --auto-rollback-enabled"

              }
            }
          }
        }
      }
    }
  }
}