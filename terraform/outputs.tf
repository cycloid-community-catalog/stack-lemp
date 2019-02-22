output "alb_front_dns_name" {
  value = "${module.lemp.alb_front_dns_name}"
}

output "alb_front_zone_id" {
  value = "${module.lemp.alb_front_zone_id}"
}

output "elasticache_address" {
  value = "${module.lemp.elasticache_address}"
}

output "rds_address" {
  value = "${module.lemp.rds_address}"
}

output "rds_port" {
  value = "${module.lemp.rds_port}"
}

output "rds_username" {
  value = "${module.lemp.rds_username}"
}

output "rds_database" {
  value = "${module.lemp.rds_database}"
}

output "iam_s3-medias_user_key" {
  value = "${module.lemp.iam_s3-medias_user_key}"
}

output "iam_s3-medias_user_secret" {
  value = "${module.lemp.iam_s3-medias_user_secret}"
}

output "s3_medias" {
  value = "${module.lemp.s3_medias}"
}

output "front_target_group_arns" {
  value = "${module.lemp.front_target_group_arns}"
}
