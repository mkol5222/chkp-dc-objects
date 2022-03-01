#!/bin/bash

PODS=$(curl -s "$MINIKUBESERVER/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt )

PODIPS=$(echo "$PODS" | jq -c -r '.items[] | .status.podIPs[] ')

echo "$PODIPS" | jq --slurp 'map(.ip) as $ips | {
      "version": "1.0",     
      "description": "Generic Data Center from Kubernetes API",
      "objects": [ { 
        name: "Pods in default NS",
        id: "AACE2E3C-5E1C-4C7F-8FA8-5FAA8E0E06CB",
        "description": "Example for IPv4 addresses collected from K8S namespace pods",
        ips: $ips 
    }]
    }'