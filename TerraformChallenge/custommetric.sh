curl -vvv -k -H "Content-Type: application/json" \
-H "X-Api-Key:09a9971f0e79e571a351f9c7651724615e14e60ddb13076" \
-X POST https://metric-api.newrelic.com/metric/v1 \
--data '[{ 
        "metrics":[{ 
           "name":"lighthouse.seo", 
           "type":"gauge", 
           "value":2.3,
           "timestamp":CURRENT_TIME, 
           "attributes":{"host.name":"dev.server.com"} 
           }, {}
           
           ] 
    }]'