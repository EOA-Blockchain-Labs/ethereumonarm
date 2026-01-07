# Ethereum on ARM Cloud Image Builder

This directory contains tools to build custom ARM64 cloud images for Ethereum nodes using [HashiCorp Packer](https://www.packer.io/).

The templates are optimized for **Full Nodes**, defaulting to high-performance ARM64 instances (4 vCPUs, 16GB RAM) and large storage (2TB).

## Prerequisites

1. **Packer**: Install Packer on your local machine.
    * MacOS: `brew install packer`
    * Linux: Follow instructions at [packer.io](https://learn.hashicorp.com/tutorials/packer/get-started-install-cli)

2. **Cloud Credentials**: You must have active credentials for the provider you want to build for.

## Usage

### AWS Images

1. **Initialize**:

    ```bash
    cd image-creation-tool/cloud
    packer init aws.pkr.hcl
    ```

2. **Build**:
    The default build uses a `t4g.xlarge` instance (4 vCPU, 16GB RAM) and a 2TB disk.

    ```bash
    # Using environment variables for auth (Recommended)
    export AWS_ACCESS_KEY_ID="your_key"
    export AWS_SECRET_ACCESS_KEY="your_secret"
    packer build aws.pkr.hcl

    # OR passing variables explicitly
    packer build \
      -var "aws_access_key=your_key" \
      -var "aws_secret_key=your_secret" \
      aws.pkr.hcl
    ```

### GCP Images

1. **Initialize**:

    ```bash
    packer init gcp.pkr.hcl
    ```

2. **Build**:
    Requires a Service Account JSON file or Application Default Credentials. Defaults to `t2a-standard-4` instance and 2TB disk.

    ```bash
    packer build \
      -var "project_id=your-project-id" \
      -var "account_file=path/to/key.json" \
      gcp.pkr.hcl
    ```

### Azure Images

1. **Initialize**:

    ```bash
    packer init azure.pkr.hcl
    ```

2. **Build**:
    Defaults to `Standard_D4ps_v5` instance and 2TB disk.

    ```bash
    # Ensure variables like ARM_CLIENT_ID are set in your environment OR pass them manually
    packer build \
      -var "resource_group=my-images-rg" \
      -var "client_id=..." \
      -var "client_secret=..." \
      -var "subscription_id=..." \
      -var "tenant_id=..." \
      azure.pkr.hcl
    ```

## Customization

You can override the following variables at build time:

* `disk_size_gb`: Size of the root disk (Default: `2048` GB).
* `instance_type` (AWS) / `machine_type` (GCP) / `vm_size` (Azure): The builder instance size.

Example:

```bash
packer build -var "disk_size_gb=100" aws.pkr.hcl
```

## Example: Successful AWS AMI Creation

When you run `packer build aws.pkr.hcl`, a successful build output will look like this:

```text
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Prevalidating AMI Name: ethereum-on-arm-node-2026-01-07-2018
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Found Image ID: ami-0071c8c431eea0edb
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Launching a source AWS instance...
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Provisioning with shell script: scripts/provision.sh
    ethereum-on-arm-aws.amazon-ebs.ethereum-node: Updating system...
    ethereum-on-arm-aws.amazon-ebs.ethereum-node: Installing Ethereum packages...
    ethereum-on-arm-aws.amazon-ebs.ethereum-node: Installing Monitoring packages...
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Stopping the source instance...
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Waiting for the instance to stop...
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Creating AMI: ethereum-on-arm-node-2026-01-07-2018
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: AMI: ami-0925af779d95c2b3e
==> ethereum-on-arm-aws.amazon-ebs.ethereum-node: Terminating the source AWS instance...
==> Builds finished. The artifacts of successful builds are:
--> ethereum-on-arm-aws.amazon-ebs.ethereum-node: AMIs were created:
us-east-1: ami-0925af779d95c2b3e
```

## Start Node with Terraform

Once your AMI is created (e.g., `ami-0925af779d95c2b3e`), you can use it in Terraform to launch a node:

```hcl
resource "aws_instance" "ethereum_node" {
  ami           = "ami-0925af779d95c2b3e"
  instance_type = "t4g.xlarge" # Recommended: 4 vCPUs, 16GB RAM

  root_block_device {
    volume_size = 2048 # 2 TB disk
    volume_type = "gp3"
  }

  tags = {
    Name = "Ethereum Node"
  }
}
```
