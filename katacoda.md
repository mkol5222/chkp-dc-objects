

# https://katacoda.com/mkol5222/scenarios/dome9-onboarding
minikube start
kubectl get nodes
git clone https://github.com/mkol5222/chkp-dc-objects.git
cd chkp-dc-objects
. ./shared-vol.sh
kubectl get pods -o wide
kubectl run web1 --image nginx
kubectl get pods -o wide
minikube service --url two-containers
# modify based on above
curl -s http://172.17.0.83:32091/dc.json

curl -O https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.tgz
tar xzvf ngrok-stable-linux-amd64.tgz
./ngrok

# now auth and create tunnel for port from 'minikube service --url two-containers'
./ngrok authtoken -bring-your-own-token
# mind correct port
./ngrok http 66666
