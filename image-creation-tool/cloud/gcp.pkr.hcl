# Google Cloud (GCP) Packer Template for Ethereum on ARM
# This template builds an Ubuntu 24.04 ARM64 Image on GCP.

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

# --- Authentication Variables ---

variable "project_id" {
  type        = string
  description = "The GCP Project ID where the image will be built and stored."
}

variable "account_file" {
  type        = string
  default     = ""
  description = "Path to the GCP Service Account JSON key file. If empty, uses Application Default Credentials."
}

variable "zone" {
  type        = string
  default     = "us-central1-a" 
  description = "GCP Zone to build in. Must support T2A (ARM) instances."
}

# --- Resource Configuration ---

variable "image_name_prefix" {
  type        = string
  default     = "ethereum-on-arm-node"
  description = "Prefix for the resulting GCP Image name."
}

variable "disk_size_gb" {
  type        = number
  default     = 2048 # 2TB
  description = "Size of the root disk in GB. Defaults to 2TB for Full Sync support."
}

variable "machine_type" {
  type        = string
  default     = "t2a-standard-4" 
  description = "GCP Machine Type. 't2a-standard-4' provides 4 vCPUs and 16GB RAM (ARM64)."
}

# --- Builder Configuration ---

source "googlecompute" "ethereum-node" {
  # Authentication
  project_id          = var.project_id
  account_file        = var.account_file
  zone                = var.zone

  # Source Image (Base OS)
  source_image_family = "ubuntu-2404-lts-arm64"
  ssh_username        = "ubuntu"
  
  # Instance Specs
  machine_type        = var.machine_type
  
  # Destination Image
  image_name          = "${var.image_name_prefix}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  image_description   = "Ethereum on ARM Node built with Packer. Specs: ${var.machine_type}, Disk: ${var.disk_size_gb}GB"
  
  # Disk Configuration
  disk_size           = var.disk_size_gb
  disk_type           = "pd-balanced" # Balance between performance and cost

  tags = ["ethereum-on-arm", "builder"]
}

# --- Build Execution ---

build {
  name    = "ethereum-on-arm-gcp"
  sources = [
    "source.googlecompute.ethereum-node"
  ]

  # Provisioning
  provisioner "shell" {
    script          = "scripts/provision.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  }

  # output manifest
  post-processor "manifest" {
    output     = "manifest-gcp.json"
    strip_path = true
  }
}
