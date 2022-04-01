# dependencies
apt update; apt install -y curl jq uuid-runtime;

while true; do
    date > /pod-data/index.html;
    
    TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
   
    curl -s "https://${KUBERNETES_SERVICE_HOST}/apis/network.openshift.io/v1/netnamespaces"  --header "Authorization: Bearer $TOKEN" \
      --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
     | jq -c -r '.items[] |{name: .netname, ips: .egressIPs} | select(.ips != null)' \
     | tee /pod-data/dc.json

    echo "created /pod-data/dc.json"
    cat /pod-data/dc.json
    echo

    sleep 5;

done
