variable "project_id" {
    default = "ayirqobzwpltyiysmwrsefbp3hmliw"
}

variable "region" {
  default = "us-west1"
}

variable "docker_image" {
  default = "us-west1-docker.pkg.dev/${var.project_id}/myapp-repo/myapp-image"
}