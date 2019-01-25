# output "redis_magento_dns" {
#   value = "${aws_route53_record.redis.fqdn}"
# }
#
# output "rds_magento_dns" {
#   value = "${aws_route53_record.rds.fqdn}"
# }

#alb

output "alb_front_dns_name" {
  value = "${aws_alb.front.dns_name}"
}

output "alb_front_zone_id" {
  value = "${aws_alb.front.zone_id}"
}

output "cache_address" {
  value = "${aws_elasticache_cluster.redis.cache_nodes.0.address}"
}
