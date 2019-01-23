# stack-lemp
(Linux, Nginx, MySQL, PHP)

Linux operating system
Nginx (Pronounced as Engine-X) web server
MySQL (RDS) database server
PHP for dynamic data processing


# Architecture

This stack will deploy a php application on X Amazon EC2 instances behind an ALB load balancer, using RDS database and optional ElasticCache/s3 medias bucket.

<img src="https://raw.githubusercontent.com/cycloid-community-catalog/stack-lemp/master/diagram.png" width="400">

  * **ALB**: Amazon application loadbalancer
  * **ASG**: Autoscaling group for fronts
  * **front**: EC2 instances from builded AMI
  * **RDS**: Amazon RDS database (mysql)
  * **Elasticache**: Amazon Elasticache (redis)

> **Pipeline** The pipeline contains a manual approval between terraform plan and terraform apply.
> That means if you trigger a terraform plan, to apply it, you have to go on terraform apply job
> and click on the `+` button to trigger it.

# Requirements

In order to run this task, couple elements are required within the infrastructure:

* Having a VPC with private & public subnets containing a bastion server that can access instances by SSH
* Having an S3 bucket for terraform remote states
* Having an S3 bucket for magento code WITH versioning enable


# Details

**Pipeline**

  * Run packer to build debian Amazon AMI with nginx, php-fpm and telegraph metrics (port 9100 prometheus format).

**Terraform**

Create:

  * ALB (loadbalancer)
  * ASG with launch_template of fronts
  * RDS

**Ansible**

  * Playbook and packer config to build a debian image with telegraf, fluentd, nginx and php-fpm installed
