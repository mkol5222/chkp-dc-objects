# dependencies
apt update; apt install -y curl jq uuid-runtime;

while true; do
    date >> /pod-data/index.html;
    echo Hello from the second container >> /pod-data/index.html;
    echo "<br>" >> /pod-data/index.html;
    
    TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)
   
    curl -s "https://kubernetes/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
    | jq -c -r '.items[] | .status.podIPs[] ' \
    | jq --slurp 'map(.ip) as $ips | {
                "version": "1.0",
                "description": "Generic Data Center from Kubernetes API",
                "objects": [ {
                   name: "Pods in default NS",
                   id: "AACE2E3C-5E1C-4C7F-8FA8-5FAA8E0E06CB",
                   "description": "Example for IPv4 addresses collected from K8S namespace pods",
                   ranges: $ips
                },
                    {
                        "name": "Pods static demo",
                        "id": "AACE2E3C-5E1C-4C7F-8FA8-5FAA8E0E06CC",
                        "description": "Pavel demo",
                    "ranges": ["8.244.1.6"]
                    }
                ]
    }' > /pod-data/dc.json

    echo "created /pod-data/dc.json"
    cat /pod-data/dc.json
    echo
    
    NAMESPACES=$(curl -s "https://kubernetes/api/v1/namespaces"  --header "Authorization: Bearer $(cat /run/secrets/kubernetes.io/serviceaccount/token)" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt | jq -r '.items[].metadata.name')
    for NAMESPACE in $NAMESPACES; do 
        curl -s "https://kubernetes/api/v1/namespaces/$NAMESPACE/pods"  \
            --header "Authorization: Bearer $TOKEN" \
            --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt | \
            jq -c -r '.items[] | .status.podIPs[]' | \
            jq -c -r --slurp --arg ns "$NAMESPACE" '{namespace: $ns, ips: [.[] | .ip ]}' | \
            jq -c --arg uuid "$(uuidgen)" '{
                    name: "ips-\(.namespace)", 
                    description: "IPs in namespace \(.namespace)",
                    uid: $uuid,
                    id: "id-\(.namespace)",
                    ranges: .ips | unique, 
                    }' 
    done | jq -c 'select((.ranges|length)>0)' | jq --slurp  ' {
                "version": "1.0",
                "description": "Generic Data Center from Kubernetes API",
                "objects":  . 
                }' > /pod-data/all-ns.json

    echo "created /pod-data/all-ns.json"
    cat /pod-data/all-ns.json
    echo 

    sleep 5;

done
