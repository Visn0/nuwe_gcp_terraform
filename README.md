# MediaMarkt Cloud Engineering challenge

Hackathon: https://nuwe.io/dev/competitions/mediamarkt-letsgo-hackathon/mediamarkt-cloud-engineering-challenge

Author: Anton Chernysh
Email: anton_chernysh@outlook.es
Linkedin: https://www.linkedin.com/in/anton-chernysh/

👉 **ABOUT**
MediaMarkt manages Peta-Bytes of information, and security goes first. In order to ensure the Minimum Least Privilege internal policy we need you to execute it and deploy an application.

In this challenge you can access to the following FrontEnd project that the MediaMarkt developer team has designated: [MediaMarkt Github link](https://github.com/nuwe-io/mms-cloud-skeleton). Your task as DevOps within the company is to be able to perform the Deployment, CI/CD, of this application in the most automated way possible.

----------------------------------------------------
**TASKS-OBJECTIVES**
- Register the Container generated by the DockerFile with Cloud Build / Artifacts.
- Generating a YAML file for Docker Composer.
- Generate the Terraform files in order to have the infrastructure as code and be able to deploy with Kubernetes.
- Answer the question to check the understanding of the Minimum Least Priviledge in the Roles assignment.

❓ **IAM QUESTION TO WRITE**
MediaMarkt wants to store sensitive information on Google Cloud Platform (GCP) and uses the principle of least privilege in the assignation of roles. Suppose you are in charge of assigning roles in GCP, admin of the organization. Your task is to decide which role would be appropriate for each group of people: the DevOps team for creating clusters in Kubernetes and Finance team in the managing billing in GCP. Detail which roles should apply and the steps they applied in the IAM GCP Console.

✨ **EVALUATION**
The points will be distributed in the following order (total 1200 points):

- Cloud Build/Artifact to generate the container (150 points).
- Generation of the Docker Composer YAML (150 points).
- Creation of the Terraform Files (400 points).
- Commands for the Deployment through TF files (kubectl) (200 points).
- Solution of the IAM Role assignation (300 points).
- In the case of a tie, the quality of the document and the quality of the delivery, as well as its explanation, will be taken into account. If in either case there is still a tie on score, the submission that was made first will be the winner.

## Dependencies

- Google Cloud SDK https://geekflare.com/gcloud-installation-guide/

- Terraform https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

- Docker https://docs.docker.com/engine/install/ubuntu/

- Kubernetes https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app?hl=es-419

----------------------------------------------------

## Summary of the stages and steps taken

### 1.Register the Container generated by the DockerFile with Cloud Build / Artifacts
Bibliography (mostly used): https://cloud.google.com/kubernetes-engine/docs/tutorials/hello-app?hl=es-419

Login to GCloud using our account
```
gcloud auth login
```

Set the PROJECT_ID env variable to the project the Hackathon gives us
```
export PROJECT_ID=<PROJECT_ID>
```

Set the project for our GCloud SDK
```
gcloud config set project $PROJECT_ID
```

Create the repository for the image
```
gcloud artifacts repositories create myapp-repo \
    --repository-format=docker \
    --location=us-west1 \
    --description="Docker repository"
```

Build the image and set the tag to the repository

```
docker buildx build -t "us-west1-docker.pkg.dev/$PROJECT_ID/myapp-repo/myapp-image" ./app/
```

You should see your images in `docker images`

Configure GCloud to have access to the repository
```
gcloud auth configure-docker us-west1-docker.pkg.dev
```

Push the compiled image to the Artifact Registry repository
```
docker push us-west1-docker.pkg.dev/$PROJECT_ID/myapp-repo/myapp-image
```

### 2.Generating a YAML file for Docker Composer
A simple docker compose file to run the application in a container
```
$ cat docker-compose.yml

version: '3'
services:
  web:
    image: us-west1-docker.pkg.dev/$PROJECT_ID/myapp-repo/myapp-image
    ports:
      - "3000:3000"
```

### 3.Generate the Terraform files in order to have the infrastructure as code and be able to deploy with Kubernetes

**Setup Environment**
Authentificate in gcloud and generate credentials for terraform
```
gcloud auth application-default login
```

Enable Kubernetes Engine API service for the project
```
gcloud services enable container.googleapis.com
```

It may need to install this plugin for terraform to be able to create the cluster  
```
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
```

**Google Kubernetes Engine**
At first I created the cluster to see if my terraform file were working.

```Terraform
provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "primary" {
  name              = "my-gke-cluster"
  location          = "us-west1"

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "my-node-pool"
  cluster    = google_container_cluster.primary.name
  location   = google_container_cluster.primary.location
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
  }
}
```

```
terraform init # Initialize the terraform project
terraform plan # Check the changes that will be applied
terraform apply # Apply the changes and create the cluster
```

I got the credentials for the cluster so I was able to access the cluster
```
gcloud container clusters get-credentials my-gke-cluster --region us-west1
```

And I finished configuring the terraform deployment by adding the kubernetes provider and its deployment configuration. You can see the full file [here](main.tf).

```
terraform plan # Check the new resources that will be created
terraform apply # Apply the changes and deploy the application
```

You can check the service by running
```
kubectl get services -n kn-app
```

It should show an external IP address for the service that you can use to access the application using the web browser.





















