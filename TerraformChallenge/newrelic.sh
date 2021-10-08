#curl -s \
#    -X GET 'https://api.newrelic.com/v2/applications.json' \
#    -H "X-Api-Key:09a9971f0e79e571a351f9c7651724615e14e60ddb13076" \
#    -d "filter[name]=dev_eu-west-1_delivery-tracker_tbd_shd_frontend" \
#    | jq  

#CORRER LIGHTHOUSE 

#GET VALUES DAS METRICAS - JSON? CAT DO FICHEIRO?

#POR VALORES ATRAVES DO JQ NO DEPLOYMENT


 
DEPLOYMENT=$(jq -n \
    --arg revision "91e796174d205d4b3f72d1d8ff13222171667927" \
    --arg changelog "frita" \
    --arg description "cenas maradas" \
    --arg user "com cerveja" \
    --arg timestamp "2021-10-08T15:15:45Z" \
    '{"deployment": { "revision": $revision, "changelog": $changelog, "description": $description, "user": $user, "timestamp": $timestamp}}')

echo $DEPLOYMENT

curl -X POST "https://api.newrelic.com/v2/applications/397086204/deployments.json" \
    -H "X-Api-Key:09a9971f0e79e571a351f9c7651724615e14e60ddb13076" \
    -i \
    -H "Content-Type: application/json" \
    -d "$DEPLOYMENT"