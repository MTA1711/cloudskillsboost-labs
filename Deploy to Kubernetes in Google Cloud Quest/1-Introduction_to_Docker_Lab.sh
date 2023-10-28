### https://partner.cloudskillsboost.google/course_sessions/5814482/labs/405579

# Task 1. Hello world

# run the hello word container to check if docker appears to be working correctly on the host
docker run hello-world

# list images on the host
docker images

# see all containers
docker ps -a

# Task 2. Build
mkdir test && cd test || exit

# create app file
cat > Dockerfile <<EOF
# Use an official Node runtime as the parent image
FROM node:lts

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Make the container's port 80 available to the outside world
EXPOSE 80

# Run app.js using node when the container launches
CMD ["node", "app.js"]
EOF

cat > app.js <<EOF
const http = require('http');

const hostname = '0.0.0.0';
const port = 80;

const server = http.createServer((req, res) => {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Hello World\n');
});

server.listen(port, hostname, () => {
    console.log('Server running at http://%s:%s/', hostname, port);
});

process.on('SIGINT', function() {
    console.log('Caught interrupt signal and will exit');
    process.exit();
});
EOF

# build image
docker build -t node-app:0.1 .
docker images


# Task 3. Run
docker run -p 4000:80 --name my-app node-app:0.1

# in another terminal
curl http://localhost:4000
docker stop my-app && docker rm my-app

docker run -p 4000:80 --name my-app -d node-app:0.1
docker logs 5360cf5cf

# rebuild docker image
docker build -t node-app:0.2 .
docker run -p 8080:80 --name my-app-2 -d node-app:0.2
docker ps
curl http://localhost:8080

# Task 4. Debug
docker logs -f my-app-2

# in another terminal
docker exec -it my-app-2 bash

docker inspect my-app-2
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' my-app-2 

# Task 5. Publish

# create docker repo in Artifact registry
gcloud  artifacts repositories create my-repository --repository-format=docker \
--location=us-east4 --description="my repository"

# set up authentication to Docker repositories in the region us-east4
gcloud auth configure-docker us-east4-docker.pkg.dev

# push the container to Artifact Registry
export PROJECT_ID=$(gcloud config get-value project)
cd ~/test || exit
# tag app image
docker build -t us-east4-docker.pkg.dev/"$PROJECT_ID"/my-repository/node-app:0.2 .
docker images
docker push us-east4-docker.pkg.dev/"$PROJECT_ID"/my-repository/node-app:0.2

# Test image

## remove all containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)

## remove all images
docker rmi -f $(docker images -aq)

## pull and run image
docker pull us-east4-docker.pkg.dev/"$PROJECT_ID"/my-repository/node-app:0.2
docker run -p 4000:80 -d us-east4-docker.pkg.dev/"$PROJECT_ID"/my-repository/node-app:0.2
curl http://localhost:4000
