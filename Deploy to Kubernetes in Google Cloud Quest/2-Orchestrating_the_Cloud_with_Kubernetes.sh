# Setup and requirements

## set default compute zone
gcloud config set compute/zone us-west1-c

## create cluster
gcloud container clusters create io

## get cluster credentials
gcloud container clusters get-credentials io

# Task 1. Get the sample code
gsutil cp -r gs://spls/gsp021/* .
cd orchestrate-with-kubernetes/kubernetes || exit

# Task 2. Quick Kubernetes Demo

## Launch and expose an nginx server
kubectl create deployment nginx --image=nginx:1.10.0
kubectl get pods
kubectl expose deployment nginx --port 80 --type LoadBalancer
URL=$(kubectl get services nginx -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
curl http://"$URL":80

# Task 4. Creating pods

cd ~/orchestrate-with-kubernetes/kubernetes || exit

## Create the monolith pod using kubectl
kubectl create -f pods/monolith.yaml
kubectl get pods
kubectl describe pods monolith

# Task 5. Interacting with pods

## In a 2nd terminal, run the command to set up port-forwarding
kubectl port-forward monolith 10080:80

## Test in another terminal
curl http://127.0.0.1:10080
curl http://127.0.0.1:10080/secure
TOKEN=$(curl http://127.0.0.1:10080/login -u user|jq -r '.token')
curl -H "Authorization: Bearer $TOKEN" http://127.0.0.1:10080/secure

## inspect pod's log
kubectl logs monolith

## stream logs to another terminal with -f option
kubectl logs -f monolith

## run an interactif shell inside the pod
kubectl exec monolith --stdin --tty -c monolith -- /bin/sh

# Task 7. Creating a service

cd ~/orchestrate-with-kubernetes/kubernetes || exit
## Create the secure-monolith pods and their configuration data
kubectl create secret generic tls-certs --from-file tls/
kubectl create configmap nginx-proxy-conf --from-file nginx/proxy.conf
kubectl create -f pods/secure-monolith.yaml

## create the service
kubectl create -f services/monolith.yaml

## allow traffic to the monolith service on the exposed nodeport 
gcloud compute firewall-rules create allow-monolith-nodeport \
  --allow=tcp:31000

curl -k https://<VM_CLUSTER_IP>:31000 ## Request will failed because there is no pod with required labels

# Task 8. Adding labels to pods

kubectl get pods -l "app=monolith"

kubectl get pods -l "app=monolith,secure=enabled" # no pod found

## set label secure=enabled to the pod
kubectl label pods secure-monolith 'secure=enabled'
kubectl get pods secure-monolith --show-labels

## check that service has an endpoint
kubectl describe services monolith | grep Endpoints

# Task 10. Creating deployments

## deploy auth microservice
kubectl create -f deployments/auth.yaml
kubectl create -f services/auth.yaml

## deploy hello microservive
kubectl create -f deployments/hello.yaml
kubectl create -f services/hello.yaml

## deploy frontend microservive
kubectl create configmap nginx-frontend-conf --from-file=nginx/frontend.conf
kubectl create -f deployments/frontend.yaml
kubectl create -f services/frontend.yaml

FRONTEND=$(kubectl get services frontend -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
curl -k https://"$FRONTEND"