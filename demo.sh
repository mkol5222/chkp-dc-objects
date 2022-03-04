startWebPods () { for N in $(seq 5); do kubectl run "web$N" --image nginx; done }

stopWebPods () { kubectl delete pod $(kubectl get pods -o json | jq -r '.items[].metadata | select (.name | startswith("web"))| .name') }

showPods () { kubectl get pods -o wide }

demoPods () { while true; do showPods; startWebPods; sleep 15; showPods; stopWebPods; sleep 15; done }

demoPods