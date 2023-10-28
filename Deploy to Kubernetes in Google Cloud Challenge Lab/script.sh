# Task 1. Create a Docker image and store the Dockerfile

#clone app source repo
source <(gsutil cat gs://cloud-training/gsp318/marking/setup_marking_v2.sh)
gcloud source repos clone valkyrie-app

#create docker app container
cat > ./valkyrie-app/DockerfileV2 <<EOL
FROM golang:1.10
WORKDIR /go/src/app
COPY source .
RUN go install -v
ENTRYPOINT ["app","-single=true","-port=8080"]
EOL

cd valkyrie-app || exit
docker build -t valkyrie-app:v0.0.2 .

bash ~/marking/step1_v2.sh

# Task 2. Test the created Docker image

docker run --rm  -p 8080:8080 valkyrie-app:v0.0.2 &
bash ~/marking/step2_v2.sh

# Task 3. Push the Docker image to the Artifact Registry

# artifact registy creation
gcloud  artifacts repositories create valkyrie-docker --repository-format=docker \
--location=us-central1 --description="Docker repository for valkyrie app"

gcloud artifacts repositories list

# configure Docker to use the Google Cloud CLI to authenticate requests to Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# image tag
docker tag valkyrie-app:v0.0.2 us-central1-docker.pkg.dev/"$GOOGLE_CLOUD_PROJECT"/valkyrie-docker/valkyrie-app:v0.0.2
docker image ls

# push image
docker push us-central1-docker.pkg.dev/"$GOOGLE_CLOUD_PROJECT"/valkyrie-docker/valkyrie-app:v0.0.2

# Task 4. Create and expose a deployment in Kubernetes

# get k8s credentials
gke-gcloud-auth-plugin --version
gcloud container clusters get-credentials valkyrie-dev \
    --zone=us-east1-d

# update deployment.yaml
sed -i "s|IMAGE_HERE|us-central1-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/valkyrie-docker/valkyrie-app:v0.0.2|g" ./valkyrie-app/k8s/deployment.yaml

# create deployment
kubectl apply -f ./valkyrie-app/k8s
kubectl get pod
kubectl get deployment
kubectl get svc
