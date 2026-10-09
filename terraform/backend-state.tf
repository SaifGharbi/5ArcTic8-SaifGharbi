terraform {
  backend "local" {
    path = "/var/lib/jenkins/terraform-state/devops/terraform.tfstate"
  }
}
