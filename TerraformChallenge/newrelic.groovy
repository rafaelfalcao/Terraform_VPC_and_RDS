
def notify(app, revision){
  wrap([$class: 'BuildUser']) {
    sh """
      APP_ID=\$(
      curl -s \
      -X GET 'https://api.newrelic.com/v2/applications.json' \
      -H "X-Api-Key:MDlhOTk3MWYwZTc5ZTU3MWEzNTFmOWM3NjUxNzI0NjE1ZTE0ZTYwZGRiMTMwNzYK" \
      -d "filter[name]=DEV_eu-west-1_delivery-tracker_tbd_shd_${app}" | \
      jq -r '.applications[0].id'
      )


        
      DEPLOYMENT=\$(
      jq -n \


      curl -X POST "https://api.newrelic.com/v2/applications/\${APP_ID}/deployments.json" \
           -H "X-Api-Key:MDlhOTk3MWYwZTc5ZTU3MWEzNTFmOWM3NjUxNzI0NjE1ZTE0ZTYwZGRiMTMwNzYK" \
           -i \
           -H "Content-Type: application/json" \
           -d "\$DEPLOYMENT"
    """
  }
}


def getSEO(app){
  wrap([$class: 'BuildUser']) {
    sh """
      APP_ID=\$(
      curl -s \
      -X GET 'https://api.newrelic.com/v2/applications.json' \
      -H "X-Api-Key:MDlhOTk3MWYwZTc5ZTU3MWEzNTFmOWM3NjUxNzI0NjE1ZTE0ZTYwZGRiMTMwNzYK" \
      -d "filter[name]=DEV_eu-west-1_delivery-tracker_tbd_shd_${app}" | \
      jq '.categories.seo.score' results.json
      )
  """
}



return this