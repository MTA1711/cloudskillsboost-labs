#delete permissive firewall-rules
gcloud compute firewall-rules delete open-access

#start bastion VM
gcloud compute instances start bastion

#create firewall-rules to allow SSH via IAP to bastion VM with tag accept-ssh-iap-ingress-ql-634
gcloud compute firewall-rules create allow-ssh-ingress-from-iap \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:22 \
  --network=acme-vpc \
  --target-tags=accept-ssh-iap-ingress-ql-634 \
  --source-ranges=35.235.240.0/20

#tag bastion VM with tag accept-ssh-iap-ingress-ql-634
gcloud compute instances add-tags bastion \
    --zone us-east1-b \
    --tags accept-ssh-iap-ingress-ql-634

#create firewall-rules to allow TCP/80 to VM with tag accept-http-ingress-ql-501
gcloud compute firewall-rules create allow-http \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:80 \
  --network=acme-vpc \
  --target-tags=accept-http-ingress-ql-501 \
  --source-ranges=0.0.0.0/0

#Tag juice-shop VM with tag accept-http-ingress-ql-501
gcloud compute instances add-tags juice-shop \
    --zone us-east1-b \
    --tags accept-http-ingress-ql-501

#create firewall-rules to allow ssh to VM with tag accept-ssh-internal-ingress-ql-394 with traffic from acme-mgmt-subnet
gcloud compute firewall-rules create allow-ssh-ingress-from-mgmt-subnet \
  --direction=INGRESS \
  --action=allow \
  --rules=tcp:22 \
  --network=acme-vpc \
  --target-tags=accept-ssh-internal-ingress-ql-394 \
  --source-ranges=192.168.10.0/24

#Tag juice-shop VM with tag accept-ssh-internal-ingress-ql-394
gcloud compute instances add-tags juice-shop \
    --zone us-east1-b \
    --tags accept-ssh-internal-ingress-ql-394