# Azure Packer Template for Ethereum on ARM
# This template builds an Ubuntu 24.04 ARM64 Managed Image on Azure.

packer {
  required_plugins {
    azure = {
      version = ">= 1.4.0"
      source  = "github.com/hashicorp/azure"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

# --- Authentication Variables ---
# Azure authentication can be complex. These variables allow using a Service Principal.
# Defaults try to pull from standard Azure environment variables.

variable "client_id" {
  type        = string
  description = "Azure Service Principal Client ID (App ID). Default: env ARM_CLIENT_ID"
  default     = env("ARM_CLIENT_ID")
}

variable "client_secret" {
  type        = string
  description = "Azure Service Principal Client Secret (Password). Default: env ARM_CLIENT_SECRET"
  default     = env("ARM_CLIENT_SECRET")
  sensitive   = true
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID. Default: env ARM_SUBSCRIPTION_ID"
  default     = env("ARM_SUBSCRIPTION_ID")
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID. Default: env ARM_TENANT_ID"
  default     = env("ARM_TENANT_ID")
}

# --- Resource Configuration ---

variable "resource_group" {
  type        = string
  description = "Azure Resource Group name where the final image will be stored."
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Azure Region to build in. Must support Ampere Altra (ARM) VMs."
}

variable "image_name_prefix" {
  type        = string
  default     = "EthereumOnARMNode"
  description = "Prefix for the Managed Image name."
}

variable "disk_size_gb" {
  type        = number
  default     = 2048 # 2TB
  description = "Size of the OS disk in GB. Defaults to 2TB for Full Sync support."
}

variable "vm_size" {
  type        = string
  default     = "Standard_D4ps_v5" 
  description = "Azure VM Size. 'Standard_D4ps_v5' provides 4 vCPUs and 16GB RAM (ARM64)."
}

# --- Builder Configuration ---

source "azure-arm" "ethereum-node" {
  # Authentication
  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id

  # Destination Image details
  managed_image_resource_group_name = var.resource_group
  managed_image_name                = "${var.image_name_prefix}-${formatdate("YYYYMMDDhhmm", timestamp())}"

  # Base Image (Canonical Ubuntu 24.04 ARM64)
  os_type         = "Linux"
  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-noble"
  image_sku       = "24_04-lts-arm64" 

  # Instance Specs
  vm_size         = var.vm_size
  location        = var.location

  # Disk Configuration
  os_disk_size_gb = var.disk_size_gb
  
  # NB: Packer automatically creates a temporary Resource Group for building and deletes it after.
}

# --- Build Execution ---

build {
  name    = "ethereum-on-arm-azure"
  sources = [
    "source.azure-arm.ethereum-node"
  ]

  # Install Ansible
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y ansible"
    ]
  }

  # Run Ansible playbook
  provisioner "ansible-local" {
    playbook_file   = "ansible/playbook.yml"
    playbook_dir    = "ansible"
    extra_arguments = ["--extra-vars", "cloud_provider=azure"]
  }

  # Output manifest
  post-processor "manifest" {
    output     = "manifest-azure.json"
    strip_path = true
  }
}
