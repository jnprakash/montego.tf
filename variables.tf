variable "gcp_project_id" {
  type    = string
  default = "gcp-montego-project"
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_credentials_json_path" {
  type    = string
  default = "/Users/jnimmala/Downloads/gcp-montego-project-bc6765945842.json"
}

variable "gcp_tfstate_backend" {
  type    = string
  default = "my-bucket-70870eb"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}