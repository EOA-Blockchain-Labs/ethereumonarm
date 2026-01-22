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

## Provisioning Architecture

The provisioning process has been migrated from legacy bash scripts to **Ansible**. This ensures better maintainability, idempotency, and consistency with the Ubuntu ARM image builds.

The provisioning is handled in two stages:

1. **Bootstrap**: A small shell script installs Ansible on the target instance.
2. **Provision**: The `ansible-local` provisioner runs the [playbook](ansible/playbook.yml) using local [variables](ansible/vars.yml).

### Customizing Provisioning

You can customize the software installed or the system configuration by modifying [image-creation-tool/cloud/ansible/vars.yml](ansible/vars.yml) before starting the build.

## Customization

You can override the following variables at build time:

| Provider | Variable | Default Value | Description |
| :--- | :--- | :--- | :--- |
| **All** | `disk_size_gb` | `2048` (2TB) | Root disk size. Required for Full Node sync. |
| **AWS** | `instance_type` | `t4g.xlarge` | 4 vCPU, 16GB RAM. |
| **GCP** | `machine_type` | `t2a-standard-4` | 4 vCPU, 16GB RAM. |
| **Azure** | `vm_size` | `Standard_D4ps_v5` | 4 vCPU, 16GB RAM. |

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

## Monthly Cost Simulation

> **Note**: These cost simulations are estimates generated by AI and may vary based on region, pricing changes, and specific configuration.

Based on the default configuration (4 vCPU, 16GB RAM, 2TB SSD) in the US region:

| Provider | Instance | Storage | Approx. Monthly Cost |
| :--- | :--- | :--- | :--- |
| **AWS** | `t4g.xlarge` | 2TB `gp3` | ~$260 |
| **GCP** | `t2a-standard-4` | 2TB `pd-balanced` | ~$310 |
| **Azure** | `Standard_D4ps_v5` | 2TB Managed SSD | ~$250 |
