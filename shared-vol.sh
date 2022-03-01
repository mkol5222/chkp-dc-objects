#!/bin/bash

kubectl delete pod two-containers

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
  labels:
    environment: production
    app: nginx
spec:
  serviceAccountName: cp-api-explorer

  volumes:
  - name: shared-data
    emptyDir: {}

  containers:

  - name: first
    image: nginx
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html

  - name: second
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/bash"]
    args:
      - "-c"
      - >
        apt update; apt install -y curl jq;
        while true; do
          date >> /pod-data/index.html;
          
          find /run/secrets/kubernetes.io/

          TOKEN="\$\(cat /run/secrets/kubernetes.io/serviceaccount/token\)"
          echo TOKEN "$TOKEN"
          curl -s "https://kubernetes/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt

           echo "prvni JQ"
          curl -s "https://kubernetes/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt | jq -c -r '.items[] | .status.podIPs[]'
            echo "cele JQ"
          curl -s "https://kubernetes/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt \
            | jq -c -r '.items[] | .status.podIPs[] ' \
            | jq --slurp 'map(.ip) as \$ips | {
                "version": "1.0",     
                "description": "Generic Data Center from Kubernetes API",
                "objects": [ { 
                   name: "Pods in default NS",
                   id: "AACE2E3C-5E1C-4C7F-8FA8-5FAA8E0E06CB",
                   "description": "Example for IPv4 addresses collected from K8S namespace pods",
                   ranges: \$ips 
                },
                    {
                        "name": "Pods static demo",
                        "id": "AACE2E3C-5E1C-4C7F-8FA8-5FAA8E0E06CC",
                        "description": "Pavel demo",
                    "ranges": ["8.244.1.6"]
                    }
                ]
            }' > /pod-data/dc.json

          echo Hello from the second container >> /pod-data/index.html;
          sleep 30;
        done
EOF

kubectl expose pod two-containers --type=NodePort --port=80

# minikube service --url two-containers

# kubectl exec two-containers -c second -i -t -- bash