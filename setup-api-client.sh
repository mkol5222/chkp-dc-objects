#!/bin/bash

kubectl create serviceaccount cp-api-explorer

cat <<EOF | kubectl apply -f -
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cp-log-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods", "pods/log"]
  verbs: ["get", "watch", "list"]
EOF

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
EOF

kubectl create rolebinding api-explorer:log-reader --clusterrole cp-log-reader --serviceaccount default:cp-api-explorer
kubectl create rolebinding api-explorer:pod-reader --role pod-reader --serviceaccount default:cp-api-explorer

SERVICE_ACCOUNT=cp-api-explorer
# Get the ServiceAccount's token Secret's name
SECRET=$(kubectl get serviceaccount ${SERVICE_ACCOUNT} -o json | jq -Mr '.secrets[].name | select(contains("token"))')

# Extract the Bearer token from the Secret and decode
TOKEN=$(kubectl get secret "${SECRET}" -o json | jq -Mr '.data.token' | base64 -d)

# Extract, decode and write the ca.crt to a temporary location
kubectl get secret "${SECRET}" -o json | jq -Mr '.data["ca.crt"]' | base64 -d > ./ca.crt

# Get the API Server location
APISERVER=https://$(kubectl -n default get endpoints kubernetes --no-headers | awk '{ print $2 }')

#curl -s "https://127.0.0.1:60862/openapi/v2"  --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt | less

MINIKUBESERVER=$(kubectl config view -o json | jq -r '.clusters[0].cluster.server ')
curl -s "$MINIKUBESERVER/openapi/v2"  --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt | jq . | less

# /api/v1/namespaces/{namespace}/pods"
curl -s "$MINIKUBESERVER/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt | jq . | less


PODS=$(curl -s "$MINIKUBESERVER/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert ./ca.crt )

kubectl delete pod/api-explorer
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: api-explorer
spec:
#  securityContext:
#    runAsUser: 1000
  serviceAccountName: cp-api-explorer
  containers:
    - name: alpine
      image: alpine
      args: ['sleep', '3600']
EOF

# inside api-explorer
kubectl exec -i -t api-explorer  -- sh

apk add curl

TOKEN=$(cat /run/secrets/kubernetes.io/serviceaccount/token)

curl -s "https://kubernetes/api/v1/namespaces/default/pods"  --header "Authorization: Bearer $TOKEN" --cacert /run/secrets/kubernetes.io/serviceaccount/ca.crt
