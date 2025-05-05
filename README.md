# stack-lemp (Linux, NGINX, MySQL, PHP)

This stack will create a full LEMP infrastructure based on Auto Scaling Groups (ASG) and an RDS database on AWS

  * Linux operating system
  * NGINX (Pronounced as Engine-X) web server
  * MySQL (RDS) database server
  * PHP-FPM for dynamic data processing

# Architecture

<p align="center">
<img src="docs/diagram.png" width="400">
</p>


  * **ALB**: Amazon Application Load Balancer
  * **ASG**: Amazon Auto Scaling group for fronts
  * **front**: EC2 instances from builded AMI
  * **RDS** (optional): Amazon RDS database (mysql)
  * **ElastiCache** (optional): Amazon ElastiCache (Redis)
  * **S3 bucket** (optional): public medias bucket

# Requirements

In order to run this task, couple elements are required within the infrastructure:

  * Having a VPC with private & public subnets [Here](https://docs.aws.amazon.com/vpc/latest/userguide/getting-started-ipv4.html#getting-started-create-vpc)
  * Having a bastion server to run Ansible like described [Here](https://docs.cycloid.io/advanced-guide/ansible-integration.html#standard-usage)
  * Having an S3 bucket to store Terraform remote states [Here](https://docs.aws.amazon.com/quickstarts/latest/s3backup/step-1-create-bucket.html)
  * Having an S3 bucket for website code **WITH** versioning enable [Here](https://docs.aws.amazon.com/quickstarts/latest/s3backup/step-1-create-bucket.html)


# Details

## Pipeline

> **Note** The pipeline contains a manual approval between terraform plan and terraform apply.
> That means if you trigger a terraform plan, to apply it, you have to go on terraform apply job
> and click on the `+` button to trigger it.

<img src="docs/pipeline.png" width="800">

**Jobs description**

  * `build-ami-front` : Build Front Amazon image AMI using Packer and Ansible.
  * `build-application`: Runs the appropriate php/composer commands and build a release file of the code to put it on S3.
  * `terraform-plan`: Terraform job that will simply make a plan of the stack.
  * `terraform-apply`: Terraform job similar to the plan one, but will actually create/update everything that needs to. Please see the plan diff for a better understanding.
  * `unittests`: Dummy job meant to eventually be replaced by proper tests or removed.
  * `application-deployment`: Simply trigger a deployment using Ansible of the last version of the code on existing instances.
  * `functional-tests`: Dummy job meant to eventually be replaced by proper functional or removed.
  * `terraform-destroy`: :warning: Terraform job meant to destroy the whole stack - **NO CONFIRMATION ASKED**. If triggered, the full project **WILL** be destroyed. Use with caution.

**Params**

|Name|Description|Type|Default|Required|
|---|---|:---:|:---:|:---:|
|`ansible_vault_password`|Password used by ansible vault to decrypt your vaulted files.|`-`|`((custom_ansible_vault_password))`|`False`|
|`ansible_version`|Ansible version used in packer and cycloid-toolkit ansible runner|`-`|`"2.9"`|`True`|
|`aws_access_key`|Amazon AWS access key for Terraform. See value format [here](https://docs.cycloid.io/advanced-guide/integrate-and-use-cycloid-credentials-manager.html#vault-in-the-pipeline)|`-`|`((aws.access_key))`|`True`|
|`aws_default_region`|Amazon AWS region to use for Terraform.|`-`|`eu-west-1`|`True`|
|`aws_secret_key`|Amazon AWS secret key for Terraform. See value format [here](https://docs.cycloid.io/advanced-guide/integrate-and-use-cycloid-credentials-manager.html#vault-in-the-pipeline)|`-`|`((aws.secret_key))`|`True`|
|`bastion_private_key_pair`|bastion SSH private key used by ansible to connect on AWS EC2 instances and the bastion itself.|`-`|`((ssh_bastion.ssh_key))`|`True`|
|`bastion_url`|bastion URL used by ansible to connect on AWS EC2 instances.|`-`|`user@bastion.server.com`|`True`|
|`config_ansible_path`|Path of Ansible files in the config Git repository|`-`|`($ .project $)/ansible`|`True`|
|`config_git_branch`|Branch of the config Git repository.|`-`|`master`|`True`|
|`config_git_private_key`|SSH key pair to fetch the config Git repository.|`-`|`((ssh_config.ssh_key))`|`True`|
|`config_git_repository`|Git repository URL containing the config of the stack.|`-`|`git@github.com:MyUser/config-lemp-app.git`|`True`|
|`config_pipeline_path`|Path of pipeline task yml files in the config Git repository. Used to override pipeline yask like build-release.yml|`-`|`($ .project $)/pipeline`|`True`|
|`config_terraform_path`|Path of Terraform files in the config git repository|`-`|`($ .project $)/terraform/($ .environment $)`|`True`|
|`customer`|Name of the Cycloid Organization, used as customer variable name.|`-`|`($ .organization_canonical $)`|`True`|
|`cycloid_toolkit_tag_prefix`|Prefix used with ansible_version to match cycloid-toolkit docker image tag. (example with "a": cycloid/cycloid-toolkit:a2.9).|`-`|`"a"`|`True`|
|`debug_public_key`|SSH pubkey injected by packer during the ec2 ami build. Used only to debug failure.|`-`|`""`|`False`|
|`deploy_bucket_name`|AWS S3 bucket name in which store the builded code of the website.|`-`|`($ .project $)-deploy`|`True`|
|`deploy_bucket_object_path`|AWS S3 bucket path in which store the builded code of the website.|`-`|`/catalog-lemp-app/($ .environment $)/lemp-app.tar.gz`|`True`|
|`env`|Name of the project's environment.|`-`|`($ .environment $)`|`True`|
|`lemp_git_branch`|Branch of the LEMP source code Git repository.|`-`|`master`|`True`|
|`lemp_git_private_key`|SSH key pair to fetch LEMP source code Git repository.|`-`|`((ssh_lemp_app.ssh_key))`|`True`|
|`lemp_git_repository`|URL to the Git repository containing LEMP website source code.|`-`|`git@github.com:MyUser/code-lemp.git`|`True`|
|`project`|Name of the project.|`-`|`($ .project $)`|`True`|
|`rds_password`|Password used for your rds. Set "empty" if you dont use databases|`-`|`((custom_rds_password))`|`True`|
|`stack_git_branch`|Branch to use on the public stack Git repository|`-`|`master`|`True`|
|`terraform_storage_bucket_name`|AWS S3 bucket name to store terraform remote state file.|`-`|`($ .organization_canonical $)-terraform-remote-state`|`True`|
|`terraform_version`|terraform version used to execute your code.|`-`|`'1.0.1'`|`True`|

## Terraform

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_health_check_matcher"></a> [application\_health\_check\_matcher](#input\_application\_health\_check\_matcher) | n/a | `number` | `200` | no |
| <a name="input_application_health_check_path"></a> [application\_health\_check\_path](#input\_application\_health\_check\_path) | n/a | `string` | `"/health-check"` | no |
| <a name="input_application_path_health_interval"></a> [application\_path\_health\_interval](#input\_application\_path\_health\_interval) | n/a | `number` | `45` | no |
| <a name="input_application_path_health_timeout"></a> [application\_path\_health\_timeout](#input\_application\_path\_health\_timeout) | n/a | `number` | `15` | no |
| <a name="input_application_ssl_cert"></a> [application\_ssl\_cert](#input\_application\_ssl\_cert) | n/a | `string` | `""` | no |
| <a name="input_application_ssl_policy"></a> [application\_ssl\_policy](#input\_application\_ssl\_policy) | n/a | `string` | `"ELBSecurityPolicy-TLS-1-2-2017-01"` | no |
| <a name="input_cache_subnet_group"></a> [cache\_subnet\_group](#input\_cache\_subnet\_group) | n/a | `string` | `""` | no |
| <a name="input_cloudfront_aliases"></a> [cloudfront\_aliases](#input\_cloudfront\_aliases) | n/a | `list(string)` | `[]` | no |
| <a name="input_cloudfront_cached_methods"></a> [cloudfront\_cached\_methods](#input\_cloudfront\_cached\_methods) | n/a | `list` | <pre>[<br>  "GET",<br>  "HEAD"<br>]</pre> | no |
| <a name="input_cloudfront_compress"></a> [cloudfront\_compress](#input\_cloudfront\_compress) | n/a | `bool` | `true` | no |
| <a name="input_cloudfront_default_ttl"></a> [cloudfront\_default\_ttl](#input\_cloudfront\_default\_ttl) | n/a | `number` | `300` | no |
| <a name="input_cloudfront_max_ttl"></a> [cloudfront\_max\_ttl](#input\_cloudfront\_max\_ttl) | n/a | `number` | `1200` | no |
| <a name="input_cloudfront_min_ttl"></a> [cloudfront\_min\_ttl](#input\_cloudfront\_min\_ttl) | n/a | `number` | `0` | no |
| <a name="input_cloudfront_minimum_protocol_version"></a> [cloudfront\_minimum\_protocol\_version](#input\_cloudfront\_minimum\_protocol\_version) | n/a | `string` | `"TLSv1"` | no |
| <a name="input_cloudfront_price_class"></a> [cloudfront\_price\_class](#input\_cloudfront\_price\_class) | n/a | `string` | `"PriceClass_200"` | no |
| <a name="input_cloudfront_ssl_certificate"></a> [cloudfront\_ssl\_certificate](#input\_cloudfront\_ssl\_certificate) | n/a | `string` | `"arn:aws:acm:us-east-1:xxxxxxxx:certificate/xxxxxxx"` | no |
| <a name="input_component"></a> [component](#input\_component) | n/a | `any` | n/a | yes |
| <a name="input_create_cloudfront_medias"></a> [create\_cloudfront\_medias](#input\_create\_cloudfront\_medias) | n/a | `bool` | `false` | no |
| <a name="input_create_elasticache"></a> [create\_elasticache](#input\_create\_elasticache) | n/a | `bool` | `false` | no |
| <a name="input_create_rds"></a> [create\_rds](#input\_create\_rds) | n/a | `bool` | `false` | no |
| <a name="input_create_s3_medias"></a> [create\_s3\_medias](#input\_create\_s3\_medias) | n/a | `bool` | `false` | no |
| <a name="input_create_ses_access"></a> [create\_ses\_access](#input\_create\_ses\_access) | n/a | `bool` | `false` | no |
| <a name="input_debian_ami_name"></a> [debian\_ami\_name](#input\_debian\_ami\_name) | n/a | `string` | `"debian-11-amd64-*"` | no |
| <a name="input_default_short_name"></a> [default\_short\_name](#input\_default\_short\_name) | n/a | `string` | `""` | no |
| <a name="input_deploy_bucket_name"></a> [deploy\_bucket\_name](#input\_deploy\_bucket\_name) | n/a | `string` | `"application-deployment"` | no |
| <a name="input_elasticache_cluster_id"></a> [elasticache\_cluster\_id](#input\_elasticache\_cluster\_id) | n/a | `string` | `""` | no |
| <a name="input_elasticache_engine"></a> [elasticache\_engine](#input\_elasticache\_engine) | n/a | `string` | `"redis"` | no |
| <a name="input_elasticache_engine_version"></a> [elasticache\_engine\_version](#input\_elasticache\_engine\_version) | n/a | `string` | `"8.0"` | no |
| <a name="input_elasticache_nodes"></a> [elasticache\_nodes](#input\_elasticache\_nodes) | n/a | `number` | `1` | no |
| <a name="input_elasticache_parameter_group_name"></a> [elasticache\_parameter\_group\_name](#input\_elasticache\_parameter\_group\_name) | n/a | `string` | `"default.redis8.0"` | no |
| <a name="input_elasticache_port"></a> [elasticache\_port](#input\_elasticache\_port) | n/a | `string` | `"6379"` | no |
| <a name="input_elasticache_type"></a> [elasticache\_type](#input\_elasticache\_type) | n/a | `string` | `"cache.t2.micro"` | no |
| <a name="input_env"></a> [env](#input\_env) | n/a | `any` | n/a | yes |
| <a name="input_extra_tags"></a> [extra\_tags](#input\_extra\_tags) | n/a | `map` | `{}` | no |
| <a name="input_front_ami_id"></a> [front\_ami\_id](#input\_front\_ami\_id) | n/a | `string` | `""` | no |
| <a name="input_front_asg_max_size"></a> [front\_asg\_max\_size](#input\_front\_asg\_max\_size) | n/a | `number` | `5` | no |
| <a name="input_front_asg_min_size"></a> [front\_asg\_min\_size](#input\_front\_asg\_min\_size) | n/a | `number` | `1` | no |
| <a name="input_front_asg_scale_down_cooldown"></a> [front\_asg\_scale\_down\_cooldown](#input\_front\_asg\_scale\_down\_cooldown) | n/a | `number` | `500` | no |
| <a name="input_front_asg_scale_down_scaling_adjustment"></a> [front\_asg\_scale\_down\_scaling\_adjustment](#input\_front\_asg\_scale\_down\_scaling\_adjustment) | n/a | `number` | `-1` | no |
| <a name="input_front_asg_scale_down_threshold"></a> [front\_asg\_scale\_down\_threshold](#input\_front\_asg\_scale\_down\_threshold) | n/a | `number` | `30` | no |
| <a name="input_front_asg_scale_up_cooldown"></a> [front\_asg\_scale\_up\_cooldown](#input\_front\_asg\_scale\_up\_cooldown) | n/a | `number` | `300` | no |
| <a name="input_front_asg_scale_up_scaling_adjustment"></a> [front\_asg\_scale\_up\_scaling\_adjustment](#input\_front\_asg\_scale\_up\_scaling\_adjustment) | n/a | `number` | `2` | no |
| <a name="input_front_asg_scale_up_threshold"></a> [front\_asg\_scale\_up\_threshold](#input\_front\_asg\_scale\_up\_threshold) | n/a | `number` | `85` | no |
| <a name="input_front_associate_public_ip_address"></a> [front\_associate\_public\_ip\_address](#input\_front\_associate\_public\_ip\_address) | n/a | `bool` | `false` | no |
| <a name="input_front_count"></a> [front\_count](#input\_front\_count) | n/a | `number` | `1` | no |
| <a name="input_front_disk_size"></a> [front\_disk\_size](#input\_front\_disk\_size) | n/a | `number` | `30` | no |
| <a name="input_front_disk_type"></a> [front\_disk\_type](#input\_front\_disk\_type) | n/a | `string` | `"gp2"` | no |
| <a name="input_front_ebs_optimized"></a> [front\_ebs\_optimized](#input\_front\_ebs\_optimized) | n/a | `bool` | `false` | no |
| <a name="input_front_type"></a> [front\_type](#input\_front\_type) | n/a | `string` | `"t3.small"` | no |
| <a name="input_front_update_min_in_service"></a> [front\_update\_min\_in\_service](#input\_front\_update\_min\_in\_service) | n/a | `number` | `1` | no |
| <a name="input_keypair_name"></a> [keypair\_name](#input\_keypair\_name) | n/a | `string` | `"cycloid"` | no |
| <a name="input_metrics_sg_allow"></a> [metrics\_sg\_allow](#input\_metrics\_sg\_allow) | n/a | `string` | `""` | no |
| <a name="input_nameregex"></a> [nameregex](#input\_nameregex) | Used to only keep few char for component like ALB name | `string` | `"/[^0-9A-Za-z-]/"` | no |
| <a name="input_organization"></a> [organization](#input\_organization) | n/a | `any` | n/a | yes |
| <a name="input_private_subnets_ids"></a> [private\_subnets\_ids](#input\_private\_subnets\_ids) | n/a | `list(string)` | `[]` | no |
| <a name="input_project"></a> [project](#input\_project) | n/a | `any` | n/a | yes |
| <a name="input_public_subnets_ids"></a> [public\_subnets\_ids](#input\_public\_subnets\_ids) | n/a | `list(string)` | `[]` | no |
| <a name="input_rds_backup_retention"></a> [rds\_backup\_retention](#input\_rds\_backup\_retention) | n/a | `number` | `7` | no |
| <a name="input_rds_database"></a> [rds\_database](#input\_rds\_database) | n/a | `string` | `"application"` | no |
| <a name="input_rds_disk_size"></a> [rds\_disk\_size](#input\_rds\_disk\_size) | n/a | `number` | `10` | no |
| <a name="input_rds_engine"></a> [rds\_engine](#input\_rds\_engine) | n/a | `string` | `"mysql"` | no |
| <a name="input_rds_engine_version"></a> [rds\_engine\_version](#input\_rds\_engine\_version) | n/a | `string` | `"8.0"` | no |
| <a name="input_rds_extra_sg_allow"></a> [rds\_extra\_sg\_allow](#input\_rds\_extra\_sg\_allow) | n/a | `string` | `""` | no |
| <a name="input_rds_multiaz"></a> [rds\_multiaz](#input\_rds\_multiaz) | n/a | `bool` | `false` | no |
| <a name="input_rds_parameters"></a> [rds\_parameters](#input\_rds\_parameters) | n/a | `string` | `"default.mysql8.0"` | no |
| <a name="input_rds_password"></a> [rds\_password](#input\_rds\_password) | n/a | `string` | `"ChangeMePls"` | no |
| <a name="input_rds_skip_final_snapshot"></a> [rds\_skip\_final\_snapshot](#input\_rds\_skip\_final\_snapshot) | n/a | `bool` | `true` | no |
| <a name="input_rds_storage_type"></a> [rds\_storage\_type](#input\_rds\_storage\_type) | n/a | `string` | `"gp2"` | no |
| <a name="input_rds_subnet_group"></a> [rds\_subnet\_group](#input\_rds\_subnet\_group) | n/a | `string` | `""` | no |
| <a name="input_rds_type"></a> [rds\_type](#input\_rds\_type) | n/a | `string` | `"db.t3.small"` | no |
| <a name="input_rds_username"></a> [rds\_username](#input\_rds\_username) | n/a | `string` | `"application"` | no |
| <a name="input_s3_medias_acl"></a> [s3\_medias\_acl](#input\_s3\_medias\_acl) | n/a | `string` | `"private"` | no |
| <a name="input_s3_medias_policy_json"></a> [s3\_medias\_policy\_json](#input\_s3\_medias\_policy\_json) | n/a | `string` | `""` | no |
| <a name="input_ses_resource_arn"></a> [ses\_resource\_arn](#input\_ses\_resource\_arn) | n/a | `string` | `"*"` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | `""` | no |
| <a name="input_zones"></a> [zones](#input\_zones) | To use specific AWS Availability Zones. | `list` | `[]` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_front_dns_name"></a> [alb\_front\_dns\_name](#output\_alb\_front\_dns\_name) | n/a |
| <a name="output_alb_front_zone_id"></a> [alb\_front\_zone\_id](#output\_alb\_front\_zone\_id) | n/a |
| <a name="output_cloudfront_medias_domain_name"></a> [cloudfront\_medias\_domain\_name](#output\_cloudfront\_medias\_domain\_name) | n/a |
| <a name="output_elasticache_address"></a> [elasticache\_address](#output\_elasticache\_address) | n/a |
| <a name="output_elasticache_cluster_id"></a> [elasticache\_cluster\_id](#output\_elasticache\_cluster\_id) | n/a |
| <a name="output_iam_ses_smtp_user_key"></a> [iam\_ses\_smtp\_user\_key](#output\_iam\_ses\_smtp\_user\_key) | n/a |
| <a name="output_iam_ses_smtp_user_secret"></a> [iam\_ses\_smtp\_user\_secret](#output\_iam\_ses\_smtp\_user\_secret) | n/a |
| <a name="output_iam_ses_user_key"></a> [iam\_ses\_user\_key](#output\_iam\_ses\_user\_key) | n/a |
| <a name="output_iam_ses_user_secret"></a> [iam\_ses\_user\_secret](#output\_iam\_ses\_user\_secret) | n/a |
| <a name="output_rds_address"></a> [rds\_address](#output\_rds\_address) | n/a |
| <a name="output_rds_database"></a> [rds\_database](#output\_rds\_database) | n/a |
| <a name="output_rds_port"></a> [rds\_port](#output\_rds\_port) | n/a |
| <a name="output_rds_username"></a> [rds\_username](#output\_rds\_username) | n/a |
| <a name="output_s3_medias"></a> [s3\_medias](#output\_s3\_medias) | n/a |



## Ansible

  * Playbook and packer config to build a debian image with telegraf, fluentd, nginx and php-fpm installed

|Name|Description|Type|Default|Required|
|---|---|:---:|:---:|:---:|
|`cycloid_files_watched`|Provide log files you want to export to Cycloid logs.|`-`|`<Default log files watched>`|`False`|
|`nginx_sites`|Contain Nginx vhosts to create on front servers. A default application and metrics vhosts are already provided.|`dict`|`<metric and application vhost>`|`False`|
|`nginx_vhost_extra_directive`|If you need extra directive to add in the default application vhost. Example basic auth, https redirect ...|`dict`|``|`False`|
|`php_version_to_install`|PHP fpm version to install.|`-`|`7.2`|`False`|
|`telegraf_install`|Install telegraf|`bool`|`true`|`False`|

# Molecule tests

Requires a bucket which contains a build of magento sources and AWS access key

virtualenv if needed
```
virtualenv    .env  --clear
source .env/bin/activate

pip install ansible==2.7 molecule==3.0a4 docker-py
```

Run the test
```
cd ansible

export AWS_ACCESS_KEY_ID=AKI...
export AWS_SECRET_ACCESS_KEY=....

export DEPLOY_BUCKET_NAME=cycloid-deploy
export DEPLOY_BUCKET_OBJECT_PATH=catalog-lemp-app/ci/lemp-app.tar.gz
export DEPLOY_BUCKET_REGION=eu-west-1

# Run molecule
molecule destroy
molecule converge
molecule verify
```
