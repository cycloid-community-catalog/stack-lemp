output "alb_front_dns_name" {
  value = "${module.lemp.alb_front_dns_name}"
}

output "alb_front_zone_id" {
  value = "${module.lemp.alb_front_zone_id}"
}

output "cache_address" {
  value = "${module.lemp.cache_address}"
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
  value = "${module.lemp.rds_database}"
}

output "iam_s3-medias_user_secret" {
  value = "${module.lemp.rds_database}"
}

output "s3_medias" {
  value = "${module.lemp.rds_database}"
}
