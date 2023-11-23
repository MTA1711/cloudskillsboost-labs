# Install Cloud Run for Anthos in the existing cluster

## set env var
export C1_ZONE=us-central1-f
export PROJECT_ID=$(gcloud config get-value project)
export C1_NAME="gke"
gcloud config set run/region us-central1
gcloud config set run/platform managed
gcloud config set eventarc/location us-central1

## Get the credentials for the GKE cluster
gcloud container clusters get-credentials $C1_NAME --zone $C1_ZONE --project "$PROJECT_ID"

## Enable Cloud Run for Anthos on your project
gcloud container fleet cloudrun enable --project="$PROJECT_ID"

## Enable the Eventarc APIs
gcloud services enable --project="$PROJECT_ID" eventarc.googleapis.com

## Install Cloud Run for Anthos on your cluster
gcloud container fleet cloudrun apply --gke-cluster=$C1_ZONE/$C1_NAME

# Task 2. Deploy a Cloud Run application

## Clone repository
git clone https://github.com/GoogleCloudPlatform/nodejs-docs-samples.git
cd nodejs-docs-samples/eventarc/pubsub/ || exit

## Build app image using cloud build
gcloud builds submit --tag gcr.io/"$PROJECT_ID"/events-pubsub

## Deploy the container image to Cloud Run
gcloud run deploy helloworld-events-pubsub-tutorial \
  --image gcr.io/"$PROJECT_ID"/events-pubsub \
  --allow-unauthenticated \
  --max-instances=1

# Task 3. Create an Eventarc trigger for Cloud Run

## Create a trigger to listen for Pub/Sub messages
## This command creates a new Pub/Sub topic and a trigger for it called events-pubsub-trigger. 
## The Pub/Sub subscription persists regardless of activity and does not expire.
gcloud eventarc triggers create events-pubsub-trigger \
  --destination-run-service=helloworld-events-pubsub-tutorial \
  --destination-run-region=us-central1 \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished"

gcloud eventarc triggers list --location=us-central1
gcloud eventarc triggers describe events-pubsub-trigger

## Find and set the Pub/Sub topic as an environment variable
export RUN_TOPIC=$(gcloud eventarc triggers describe events-pubsub-trigger \
  --format='value(transport.pubsub.topic)')

## Publish message to the topic
gcloud pubsub topics publish "$RUN_TOPIC" --message "Runner"

# Task 4. Prepare the environment for Eventarc and Cloud Run for Anthos

## Create a service account to use when creating triggers
TRIGGER_SA=pubsub-to-anthos-trigger
gcloud iam service-accounts create $TRIGGER_SA

## Grant appropriate roles to the new service account
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${TRIGGER_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role "roles/pubsub.subscriber"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${TRIGGER_SA}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role "roles/monitoring.metricWriter"

## Enable GKE destinations for Eventarc
gcloud eventarc gke-destinations init

# Task 5. Deploy the Cloud Run for Anthos application

## Deploy to cloud run for anthos
gcloud run deploy subscriber-service \
  --cluster $C1_NAME \
  --cluster-location $C1_ZONE \
  --platform gke \
  --image gcr.io/$(gcloud config get-value project)/events-pubsub


# Task 6. Create an Eventarc trigger for Cloud Run on Anthos

## Create a trigger to listen for Pub/Sub messages
gcloud eventarc triggers create pubsub-trigger \
  --location=us-central1 \
  --destination-gke-cluster=$C1_NAME \
  --destination-gke-location=$C1_ZONE \
  --destination-gke-namespace=default \
  --destination-gke-service=subscriber-service \
  --destination-gke-path=/ \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
  --service-account=${TRIGGER_SA}@"${PROJECT_ID}".iam.gserviceaccount.com

## Confirm that the trigger was successfully created
gcloud eventarc triggers list --location=us-central1

## Find and set the Pub/Sub topic as an environment variable
export RUN_TOPIC=$(gcloud eventarc triggers describe pubsub-trigger \
  --location=us-central1 \
  --format='value(transport.pubsub.topic)')

## Send a message to the Pub/Sub topic to generate an event
gcloud pubsub topics publish "$RUN_TOPIC" --message "Cloud Run on Anthos"