packer {
  required_version = ">= 1.7.0"

  required_plugins {
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_region" {}
variable "packer_instance_type" {}
variable "organization" {}
variable "project" {}
variable "component" {}
variable "env" {}
variable "role" {}
variable "public_key" {}
variable "vault_password" {}
variable "ansible_version" {}
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "skip_tags" {}

variable "inventory_groups" {}

locals {
  # inventory_groups = ["tag_role_${var.role}", "tag_project_${var.project}", "tag_env_${var.env}"]
  inventory_groups = split(",", var.inventory_groups)
}


source "amazon-ebs" "debian" {
  region        = var.aws_region
  instance_type = var.packer_instance_type
  ssh_username  = "admin"
  ami_name      = "${var.organization}_${var.project}_${var.component}_${var.env}_${var.role}_${formatdate("YYYYMMDDhhmmss", timestamp())}"

  source_ami_filter {
    filters = {
      architecture        = "x86_64"
      virtualization-type = "hvm"
      name                = "debian-12-*"
      root-device-type    = "ebs"
    }
    owners      = ["136693071363"]
    most_recent = true
  }

  run_tags = {
    Name                 = "${var.organization}_${var.project}_${var.component}_${var.env}-${timestamp()}"
    client               = var.organization
    organization         = var.organization
    component            = var.component
    env                  = var.env
    project              = var.project
    role                 = var.role
    "cycloid.io"         = "true"
    packer_build         = "true"
    monitoring-discovery = "false"
  }

  tags = {
    Name         = "${var.organization}_${var.project}_${var.component}_${var.env}-${timestamp()}"
    client       = var.organization
    organization = var.organization
    component    = var.component
    env          = var.env
    project      = var.project
    role         = var.role
    "cycloid.io" = "true"
  }
}

build {
  name    = "debian-ansible-build"
  sources = ["source.amazon-ebs.debian"]

  provisioner "file" {
    source      = "merged-stack/packer/front/first-boot.yml.tpl"
    destination = "/tmp/first-boot.yml.tpl"
  }

  provisioner "file" {
    source      = "merged-stack/packer/front/user-data.sh.tpl"
    destination = "/tmp/user-data.sh.tpl"
  }

  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloudinit to be done... Can take up to 300 sec'",
      "for i in $(seq 1 300); do [ -f /var/lib/cloud/instance/boot-finished ] && break || sleep 1; done",
      "echo '${var.public_key}' > /home/admin/.ssh/authorized_keys",
      "if [ -z '${var.vault_password}' ]; then echo 'fake' > /home/admin/.vault-password; else echo '${var.vault_password}' > /home/admin/.vault-password; fi",
      "sudo apt-get update -qq > /dev/null",
      "sudo apt-get upgrade -yqq > /dev/null",
      "sudo apt-get install -yqq build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv python3-setuptools git curl jq > /dev/null",
      "sudo apt-get install -yqq python3-pip",
      "sudo rm /usr/lib/python3.11/EXTERNALLY-MANAGED",
      "sudo python3 -m pip install --upgrade pip",
      "sudo pip3 install -U cryptography==38.0.4 --break-system-packages",
      "sudo pip3 install -q ansible==${var.ansible_version} --break-system-packages",
      "echo 'Host *' >> /home/admin/.ssh/config",
      "echo 'StrictHostKeyChecking no' >> /home/admin/.ssh/config",
      "sleep 60"
    ]
  }

  provisioner "ansible-local" {
    command          = "ANSIBLE_STDOUT_CALLBACK=default ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1 ansible-playbook"
    playbook_dir     = "merged-stack/packer/front"
    playbook_file    = "merged-stack/packer/front/local.yml"
    inventory_groups = local.inventory_groups
    extra_arguments = [
      "-e organization=${var.organization}",
      "-e env=${var.env}",
      "-e component=${var.component}",
      "-e project=${var.project}",
      "-e client=${var.organization}",
      "-e customer=${var.organization}",
      "-e role=${var.role}",
      "-e aws_access_key_id=${var.aws_access_key_id}",
      "-e aws_secret_access_key=${var.aws_secret_access_key}"
    ]
  }

  provisioner "ansible-local" {
    command           = "ANSIBLE_STDOUT_CALLBACK=default ANSIBLE_FORCE_COLOR=1 PYTHONUNBUFFERED=1 ansible-playbook"
    galaxy_file       = "merged-stack/requirements.yml"
    galaxy_roles_path = "roles"
    playbook_file     = "merged-stack/lemp.yml"
    playbook_dir      = "merged-stack"
    staging_directory = "/home/admin/${var.organization}"
    group_vars        = "merged-stack/group_vars/"
    inventory_groups  = local.inventory_groups
    extra_arguments = [
      "-e ec2_tag_env=${var.env}",
      "-e ec2_tag_component=${var.component}",
      "-e ec2_tag_project=${var.project}",
      "-e ec2_tag_client=${var.organization}",
      "-e ec2_tag_role=${var.role}",
      "-e organization=${var.organization}",
      "-e env=${var.env}",
      "-e component=${var.component}",
      "-e project=${var.project}",
      "-e client=${var.organization}",
      "-e customer=${var.organization}",
      "-e role=${var.role}",
      "--skip-tags=${var.skip_tags}",
      "--vault-password-file /home/admin/.vault-password"
    ]
  }
}
