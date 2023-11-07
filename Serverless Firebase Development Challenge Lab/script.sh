# Task 1. Create a Firestore database

gcloud firestore databases create --region=nam5 

# Task 2. Populate the Database
cd ~/pet-theory/lab06/firebase-import-csv/solution || exit
npm install
node index.js netflix_titles_original.csv

# Task 3. Create a REST API
cd ~/pet-theory/lab06/firebase-rest-api/solution-01 || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/rest-api:0.1 .

gcloud run deploy netflix-dataset-service-577 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/rest-api:0.1 \
  --platform managed \
  --allow-unauthenticated \
  --max-instances 1 \
  --region us-east1

# Task 4. Firestore API access

cd ~/pet-theory/lab06/firebase-rest-api/solution-02 || exit

gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/rest-api:0.2 .

gcloud run deploy netflix-dataset-service-577 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/rest-api:0.2 \
  --platform managed \
  --allow-unauthenticated \
  --max-instances 1 \
  --region us-east1

SERVICE_URL=$(gcloud run services describe netflix-dataset-service-577 \
--platform managed \
--region us-east1 \
--format "value(status.url)")

curl -X GET "$SERVICE_URL"/2020
curl -X GET "$SERVICE_URL"/2019


# Task 5. Deploy the Staging Frontend

cd ~/pet-theory/lab06/firebase-frontend || exit

# build staging frontend using cloud build
gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-staging:0.1 .

#deploy to cloud run the staging frontend
gcloud run deploy frontend-staging-service-484 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-staging:0.1 \
  --platform managed \
  --allow-unauthenticated \
  --max-instances 1 \
  --region us-east1


# Task 6. Deploy the Production Frontend

cd ~/pet-theory/lab06/firebase-frontend/ || exit

# update public/app.js
sed -i "s|data/netflix.json|$SERVICE_URL/2020|g" ./public/app.js

# build production frontend using cloud build
gcloud builds submit \
  --tag gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-production:0.1 .

# deploy to cloud run the production frontend
gcloud run deploy frontend-production-service-875 \
  --image gcr.io/"$GOOGLE_CLOUD_PROJECT"/frontend-production:0.1 \
  --platform managed \
  --allow-unauthenticated \
  --max-instances 1 \
  --region us-east1


