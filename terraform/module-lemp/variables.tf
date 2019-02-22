variable "aws_region" {
  default = "eu-west-1"
}

variable "bastion_sg_allow" {}

variable "metrics_sg_allow" {
  default = ""
}

variable "project" {
  default = "lemp"
}

variable "env" {}

variable "customer" {}

variable "short_region" {
  type = "map"

  default = {
    ap-northeast-1 = "ap-no1"
    ap-northeast-2 = "ap-no2"
    ap-southeast-1 = "ap-so1"
    ap-southeast-2 = "ap-so2"
    eu-central-1   = "eu-ce1"
    eu-west-1      = "eu-we1"
    eu-west-3      = "eu-we3"
    sa-east-1      = "sa-ea1"
    us-east-1      = "us-ea1"
    us-west-1      = "us-we1"
    us-west-2      = "us-we2"
  }
}

variable "keypair_name" {
  default = "cycloid"
}

variable "private_subnets_ids" {
  type = "list"
}

variable "public_subnets_ids" {
  type = "list"
}

variable "cache_subnet_group" {
  default = ""
}

variable "vpc_id" {}

variable "zones" {
  default = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

#
# s3 medias
#

variable "create_s3_medias" {
  default = false
}

#
# RDS
#

variable "create_rds" {
  default = false
}

variable "rds_database" {
  default = "application"
}

variable "rds_disk_size" {
  default = 10
}

variable "rds_multiaz" {
  default = false
}

variable "rds_password" {
  default = "ChangeMePls"
}

variable "rds_type" {
  default = "db.t3.small"
}

variable "rds_username" {
  default = "application"
}

variable "rds_storage_type" {
  default = "gp2"
}

variable "rds_subnet_group" {
  default = ""
}

variable "rds_parameters" {
  default = "default.mysql5.7"
}

variable "rds_engine" {
  default = "mysql"
}

variable "rds_engine_version" {
  default = "5.7.16"
}

variable "rds_backup_retention" {
  default = 7
}

variable "rds_skip_final_snapshot" {
  default = true
}

#
# Application
#

variable "vault_password" {
  default = "tmp"
}

variable "application_ssl_cert" {
  default = ""
}

variable "application_ssl_policy" {
  # ELBSecurityPolicy-2015-05
  default = "ELBSecurityPolicy-TLS-1-2-2017-01"
}

variable "application_health_check_path" {
  default = "/health-check"
}

variable "application_health_check_matcher" {
  default = 200
}

variable "application_path_health_timeout" {
  default = 15
}

variable "application_path_health_interval" {
  default = 45
}

###

# front

###

variable "front_disk_size" {
  default = 30
}

variable "front_disk_type" {
  default = "gp2"
}

variable "front_type" {
  default = "t3.small"
}

variable "front_ebs_optimized" {
  default = false
}

variable "front_count" {
  default = 1
}

variable "front_associate_public_ip_address" {
  default = false
}

variable "debian_ami_name" {
  default = "debian-stretch-*"
}

#
# ASG
#

variable "front_asg_min_size" {
  default = 1
}

variable "front_asg_max_size" {
  default = 5
}

variable "front_asg_scale_up_scaling_adjustment" {
  default = 2
}

variable "front_asg_scale_up_cooldown" {
  default = 300
}

variable "front_asg_scale_up_threshold" {
  default = 85
}

variable "front_asg_scale_down_scaling_adjustment" {
  default = -1
}

variable "front_asg_scale_down_cooldown" {
  default = 500
}

variable "front_asg_scale_down_threshold" {
  default = 30
}

variable "front_update_min_in_service" {
  default = 0
}

###

# ElastiCache

###

variable "create_elasticache" {
  default = false
}

variable "elasticache_type" {
  default = "cache.t2.micro"
}

variable "elasticache_nodes" {
  default = 1
}

variable "elasticache_engine" {
  default = "redis"
}

variable "elasticache_parameter_group_name" {
  default = "default.redis5.0"
}

variable "elasticache_engine_version" {
  default = "5.0.0"
}

variable "elasticache_port" {
  default = "6379"
}

variable "deploy_bucket_name" {
  default = "application-deployment"
}
