#!/bin/bash

# SA to obtain pods
kubectl create serviceaccount cp-api-explorer

kubectl create clusterrole ns-reader --verb=get,list,watch --resource=namespaces,pods
kubectl create clusterrolebinding ns-reader --clusterrole ns-reader --serviceaccount default:cp-api-explorer

# RO access to pods in default ns
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

# bind role to SA
# kubectl create rolebinding api-explorer:pod-reader --role pod-reader --serviceaccount default:cp-api-explorer

# if needed to recreate
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
    image: ubuntu
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/bash"]
    args:
      - "-c"
      - "echo 'YXB0IHVwZGF0ZTsgYXB0IGluc3RhbGwgLXkgY3VybCBqcTsKCndoaWxlIHRydWU7IGRvCiAgICBkYXRlID4+IC9wb2QtZGF0YS9pbmRleC5odG1sOwogICAgZWNobyBIZWxsbyBmcm9tIHRoZSBzZWNvbmQgY29udGFpbmVyID4+IC9wb2QtZGF0YS9pbmRleC5odG1sOwogICAgZWNobyAiPGJyPiIgPj4gL3BvZC1kYXRhL2luZGV4Lmh0bWw7CiAgICAKICAgIGZpbmQgL3J1bi9zZWNyZXRzL2t1YmVybmV0ZXMuaW8vCiAgICAKICAgIFRPS0VOPSQoY2F0IC9ydW4vc2VjcmV0cy9rdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3Rva2VuKQogICAKICAgIGVjaG8gIkF1dGhvcml6YXRpb246IEJlYXJlciAkVE9LRU4iCiAgICBjYXQgIC9ydW4vc2VjcmV0cy9rdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L2NhLmNydAogICAgCiAgICAKICAgIGN1cmwgLXMgImh0dHBzOi8va3ViZXJuZXRlcy9hcGkvdjEvbmFtZXNwYWNlcy9kZWZhdWx0L3BvZHMiICAtLWhlYWRlciAiQXV0aG9yaXphdGlvbjogQmVhcmVyICRUT0tFTiIgLS1jYWNlcnQgL3J1bi9zZWNyZXRzL2t1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvY2EuY3J0CiAgICAKICAgIGVjaG8gImluc2VjdXJlIgogICAgY3VybCAtcyAiaHR0cHM6Ly9rdWJlcm5ldGVzL2FwaS92MS9uYW1lc3BhY2VzL2RlZmF1bHQvcG9kcyIgIC0taGVhZGVyICJBdXRob3JpemF0aW9uOiBCZWFyZXIgJFRPS0VOIiAtLWluc2VjdXJlCiAgICAKICAgIGVjaG8gInBydm5pIEpRIgogICAgY3VybCAtcyAiaHR0cHM6Ly9rdWJlcm5ldGVzL2FwaS92MS9uYW1lc3BhY2VzL2RlZmF1bHQvcG9kcyIgIC0taGVhZGVyICJBdXRob3JpemF0aW9uOiBCZWFyZXIgJFRPS0VOIiAtLWNhY2VydCAvcnVuL3NlY3JldHMva3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9jYS5jcnQgfCBqcSAtYyAtciAnLml0ZW1zW10gfCAuc3RhdHVzLnBvZElQc1tdJwogICAgZWNobyAiY2VsZSBKUSIKICAgIGN1cmwgLXMgImh0dHBzOi8va3ViZXJuZXRlcy9hcGkvdjEvbmFtZXNwYWNlcy9kZWZhdWx0L3BvZHMiICAtLWhlYWRlciAiQXV0aG9yaXphdGlvbjogQmVhcmVyICRUT0tFTiIgLS1jYWNlcnQgL3J1bi9zZWNyZXRzL2t1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvY2EuY3J0IFwKICAgIHwganEgLWMgLXIgJy5pdGVtc1tdIHwgLnN0YXR1cy5wb2RJUHNbXSAnIFwKICAgIHwganEgLS1zbHVycCAnbWFwKC5pcCkgYXMgJGlwcyB8IHsKICAgICAgICAgICAgICAgICJ2ZXJzaW9uIjogIjEuMCIsCiAgICAgICAgICAgICAgICAiZGVzY3JpcHRpb24iOiAiR2VuZXJpYyBEYXRhIENlbnRlciBmcm9tIEt1YmVybmV0ZXMgQVBJIiwKICAgICAgICAgICAgICAgICJvYmplY3RzIjogWyB7CiAgICAgICAgICAgICAgICAgICBuYW1lOiAiUG9kcyBpbiBkZWZhdWx0IE5TIiwKICAgICAgICAgICAgICAgICAgIGlkOiAiQUFDRTJFM0MtNUUxQy00QzdGLThGQTgtNUZBQThFMEUwNkNCIiwKICAgICAgICAgICAgICAgICAgICJkZXNjcmlwdGlvbiI6ICJFeGFtcGxlIGZvciBJUHY0IGFkZHJlc3NlcyBjb2xsZWN0ZWQgZnJvbSBLOFMgbmFtZXNwYWNlIHBvZHMiLAogICAgICAgICAgICAgICAgICAgcmFuZ2VzOiAkaXBzCiAgICAgICAgICAgICAgICB9LAogICAgICAgICAgICAgICAgICAgIHsKICAgICAgICAgICAgICAgICAgICAgICAgIm5hbWUiOiAiUG9kcyBzdGF0aWMgZGVtbyIsCiAgICAgICAgICAgICAgICAgICAgICAgICJpZCI6ICJBQUNFMkUzQy01RTFDLTRDN0YtOEZBOC01RkFBOEUwRTA2Q0MiLAogICAgICAgICAgICAgICAgICAgICAgICAiZGVzY3JpcHRpb24iOiAiUGF2ZWwgZGVtbyIsCiAgICAgICAgICAgICAgICAgICAgInJhbmdlcyI6IFsiOC4yNDQuMS42Il0KICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICBdCiAgICB9JyA+IC9wb2QtZGF0YS9kYy5qc29uCiAgICAKICAgIAogICAgc2xlZXAgMzA7Cgpkb25lCg==' | base64 -d | bash - "
      
EOF

kubectl expose pod two-containers --type=NodePort --port=80

# minikube service --url two-containers

# kubectl exec two-containers -c second -i -t -- bash

