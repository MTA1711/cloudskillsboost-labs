# Lab setup
gcloud config set run/region us-central1
gcloud config set run/platform managed
git clone https://github.com/rosera/pet-theory.git && cd pet-theory/lab07 || exit

# Task 1. Enable a Public Service

cd unit-api-billing || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/billing-staging-api:0.1
  
gcloud run deploy public-billing-service-503 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/billing-staging-api:0.1 \
  --platform managed \
  --allow-unauthenticated

# Task 2. Deploy a Frontend Service
  
cd ../staging-frontend-billing || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-staging:0.1
 
gcloud run deploy frontend-staging-service-506 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-staging:0.1 \
  --platform managed \
  --allow-unauthenticated
  
# Task 3. Deploy a Private Service

gcloud run delete public-billing-service-503

cd ../staging-api-billing || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/billing-staging-api:0.2
  
gcloud run deploy private-billing-service-460 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/billing-staging-api:0.2 \
  --platform managed

BILLING_URL=$(gcloud run services describe private-billing-service-460 \
--platform managed \
--region us-central1 \
--format "value(status.url)")

# Task 4. Create a Billing Service Account

gcloud iam service-accounts create billing-service-sa-418 \
    --description="Billing Service Cloud Run" \
    --display-name="Billing Service Cloud Run"

# Task 5. Deploy the Billing Service

cd ../prod-api-billing || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/billing-prod-api:0.1
  
gcloud run deploy billing-prod-service-801 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/billing-prod-api:0.1 \
  --platform managed \
  --service-account billing-service-sa-418@qwiklabs-gcp-03-60bd391d8a5d.iam.gserviceaccount.com

PROD_BILLING_URL=$(gcloud run services \
describe private-billing-service-460 \
--platform managed \
--region us-central1 \
--format "value(status.url)")

curl -X get -H "Authorization: Bearer \
$(gcloud auth print-identity-token)" \
"$PROD_BILLING_URL"

# Task 6. Frontend Service Account

gcloud iam service-accounts create frontend-service-sa-154 \
    --description="Billing Service Cloud Run Invoker" \
    --display-name="Billing Service Cloud Run Invoker" 

gcloud projects add-iam-policy-binding "$GOOGLE_CLOUD_PROJECT" \
    --member="serviceAccount:frontend-service-sa-154@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com" \
	--role="roles/run.invoker"
	
# Task 7. Redeploy the Frontend Service

cd ../prod-frontend-billing || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-prod:0.1
 
gcloud run deploy frontend-prod-service-300 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-prod:0.1 \
  --platform managed \
  --allow-unauthenticated \
  --service-account frontend-service-sa-154@"$GOOGLE_CLOUD_PROJECT".iam.gserviceaccount.com \
  --set-env-vars=BILLING_URL="$PROD_BILLING_URL"

