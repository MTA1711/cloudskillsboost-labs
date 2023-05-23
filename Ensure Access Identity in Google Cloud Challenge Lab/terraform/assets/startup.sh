sudo apt-get install -y kubectl google-cloud-sdk-gke-gcloud-auth-plugin
# echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
# source ~/.bashrc
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
gcloud container clusters get-credentials "${CLUSTER_NAME}" --internal-ip --project="${PROJECT_ID}" --zone "${CLUSTER_ZONE}"
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
