# prepare
crc start
eval $(crc oc-env)
# oc login -u developer https://api.crc.testing:6443
oc login -u kubeadmin

# define
oc patch netnamespace  app1 --type=merge -p '{"egressIPs": ["192.168.1.100"]}'
oc get nodes
oc patch hostsubnet  crc-8k6jw-master-0 --type=merge -p '{"egressCIDRs": ["192.168.1.0/24"]}'

# test with api proxy
oc proxy --port 8080
curl localhost:8080/apis/network.openshift.io/v1/netnamespaces

curl -s localhost:8080/apis/network.openshift.io/v1/netnamespaces | jq -c -r '.items[] |{name: .netname, ips: .egressIPs} | select(.ips != null)'
# {"name":"app1","ips":["192.168.1.100"]}
