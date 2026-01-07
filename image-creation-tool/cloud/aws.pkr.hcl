# AWS Packer Template for Ethereum on ARM
# This template builds an Ubuntu 24.04 ARM64 AMI optimized for Ethereum nodes.

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# --- Authentication Variables ---
# It is recommended to use environment variables or a credentials file,
# but these variables allow manual overrides if needed.

variable "aws_access_key" {
  type        = string
  default     = env("AWS_ACCESS_KEY_ID")
  description = "AWS Access Key ID. Defaults to env var AWS_ACCESS_KEY_ID."
}

variable "aws_secret_key" {
  type        = string
  default     = env("AWS_SECRET_ACCESS_KEY")
  description = "AWS Secret Access Key. Defaults to env var AWS_SECRET_ACCESS_KEY."
  sensitive   = true
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Region to build the AMI in (e.g., us-east-1, eu-central-1)."
}

# --- Resource Configuration ---

variable "ami_name_prefix" {
  type        = string
  default     = "ethereum-on-arm-node"
  description = "Prefix for the resulting AMI name."
}

variable "disk_size_gb" {
  type        = number
  default     = 2048 # 2TB
  description = "Size of the root EBS volume in GB. Defaults to 2TB for Full Sync support."
}

variable "instance_type" {
  type        = string
  default     = "t4g.xlarge" 
  description = "AWS Instance type for the builder. 't4g.xlarge' provides 4 vCPUs and 16GB RAM."
}

# --- Data Source: Base Image ---

# Fetch the latest Ubuntu 24.04 LTS ARM64 Server AMI
data "amazon-ami" "ubuntu-arm64" {
  filters = {
    name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"] # Canonical's official AWS account ID
  region      = var.region
}

# --- Builder Configuration ---

source "amazon-ebs" "ethereum-node" {
  # Authentication
  access_key    = var.aws_access_key
  secret_key    = var.aws_secret_key
  region        = var.region

  # Instance Specs
  ami_name      = "${var.ami_name_prefix}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  instance_type = var.instance_type
  
  # Base Image
  source_ami    = data.amazon-ami.ubuntu-arm64.id
  ssh_username  = "ubuntu"

  # Root Volume Configuration
  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = var.disk_size_gb
    volume_type           = "gp3" # General Purpose SSD (latest generation)
    delete_on_termination = true
  }

  # Build Metadata
  tags = {
    Name        = "EthereumOnARM-Builder"
    Environment = "Build"
    Project     = "EthereumOnARM"
    Architecture = "arm64"
  }
}

# --- Build Execution ---

build {
  name    = "ethereum-on-arm-aws"
  sources = [
    "source.amazon-ebs.ethereum-node"
  ]

  # Upload and execute the provisioning script
  provisioner "shell" {
    script = "scripts/provision.sh"
    # execute_command ensures sudo variables are preserved
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
  }

  # Generate a manifest file with artifact details
  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
