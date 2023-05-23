### In cloud console


# private cluster creation in us-east1 region (same region than orca-build-subnet)
gcloud beta container clusters create orca-cluster-244 \
	--enable-private-endpoint \
	--master-ipv4-cidr 172.16.0.16/28 \
    --enable-ip-alias \
	--enable-private-nodes \
	--service-account=orca-private-cluster-957-sa@qwiklabs-gcp-02-a8a7cf5488a1.iam.gserviceaccount.com \
	--subnetwork=orca-build-subnet \
	--network=orca-build-vpc \
	--num-nodes=1 \
	--location=us-east1

# Enable jump host to access private cluster by specifing jump host's private ip address
gcloud container clusters update orca-cluster-244 \
    --enable-master-authorized-networks \
    --master-authorized-networks=192.168.10.2/32 --location=us-east1

### In jump host SSH cmd

# Gke auth plugin installation
sudo apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin
echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
source ~/.bashrc

# Get cluster credential
gcloud container clusters get-credentials orca-cluster-244 --internal-ip --project=qwiklabs-gcp-02-a8a7cf5488a1 --location=us-east1

# install sample app
kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0
