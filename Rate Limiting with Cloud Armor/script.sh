## Task 1. Configure HTTP and health check firewall rules

# Create the HTTP firewall rule
gcloud compute firewall-rules create default-allow-http --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

# Create the health check firewall rules
gcloud compute firewall-rules create default-allow-health-check --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=tcp --source-ranges=130.211.0.0/22,35.191.0.0/16 --target-tags=http-server

## Task 2. Configure instance templates and create instance groups

# Configure the instance templates
gcloud compute instance-templates create us-east1-template  --machine-type=n1-standard-1 --network-interface=network-tier=PREMIUM,subnet=default \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true \
    --maintenance-policy=MIGRATE --provisioning-model=STANDARD  --region=us-east1 --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=us-east1-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230814,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

gcloud compute instance-templates create europe-west1-template --machine-type=n1-standard-1 --network-interface=network-tier=PREMIUM,subnet=default \
    --metadata=startup-script-url=gs://cloud-training/gcpnet/httplb/startup.sh,enable-oslogin=true \
    --maintenance-policy=MIGRATE --provisioning-model=STANDARD --region=europe-west1 --tags=http-server \
    --create-disk=auto-delete=yes,boot=yes,device-name=us-east1-template,image=projects/debian-cloud/global/images/debian-11-bullseye-v20230814,mode=rw,size=10,type=pd-balanced \
    --no-shielded-secure-boot --shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any

# Create the managed instance groups
gcloud beta compute instance-groups managed create us-east1-mig  --base-instance-name=us-east1-mig --size=1 --template=us-east1-template --zones=us-east1-b,us-east1-c,us-east1-d \
    --target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair

gcloud beta compute instance-groups managed set-autoscaling us-east1-mig  --region=us-east1 --cool-down-period=45 --max-num-replicas=5 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8

gcloud beta compute instance-groups managed create europe-west1-mig --base-instance-name=europe-west1-mig --size=1 --template=europe-west1-template --zones=europe-west1-b,europe-west1-d,europe-west1-c \
--target-distribution-shape=EVEN --instance-redistribution-type=PROACTIVE --list-managed-instances-results=PAGELESS --no-force-update-on-repair

gcloud beta compute instance-groups managed set-autoscaling europe-west1-mig --region=europe-west1 --cool-down-period=45 --max-num-replicas=5 --min-num-replicas=1 --mode=on --target-cpu-utilization=0.8


## Task 4. Test the HTTP Load Balancer

# Stress test the HTTP Load Balancer
gcloud compute instances create siege-vm --zone=us-west1-c --machine-type=n1-standard-1 --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default


## Task 5. Create Cloud Armor rate limiting policy
gcloud compute security-policies create rate-limit-siege \
    --description "policy for rate limiting"

gcloud beta compute security-policies rules create 100 \
    --security-policy=rate-limit-siege     \
    --expression="true" \
    --action=rate-based-ban                   \
    --rate-limit-threshold-count=50           \
    --rate-limit-threshold-interval-sec=120   \
    --ban-duration-sec=300           \
    --conform-action=allow           \
    --exceed-action=deny-404         \
    --enforce-on-key=IP

gcloud compute backend-services update http-backend \
    --security-policy rate-limit-siege