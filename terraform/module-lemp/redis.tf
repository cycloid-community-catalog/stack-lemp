resource "aws_security_group" "redis" {
  count       = var.create_elasticache ? 1 : 0
  name        = "${local.name_prefix}-${var.elasticache_engine}"
  description = "${var.elasticache_engine} ${var.env} for ${var.project}"
  vpc_id      = var.vpc_id

  ingress {
    from_port = var.elasticache_port
    to_port   = var.elasticache_port
    protocol  = "tcp"

    security_groups = [
      aws_security_group.front.id,
    ]
  }

  tags = merge(var.extra_tags, {
    Name = "${local.name_prefix}-${var.elasticache_engine}"
    role = "redis"
  })
}

resource "aws_elasticache_cluster" "redis" {
  count                = var.create_elasticache ? 1 : 0
  cluster_id           = local.elasticache_cluster_id
  engine               = var.elasticache_engine
  engine_version       = var.elasticache_engine_version
  node_type            = var.elasticache_type
  port                 = var.elasticache_port
  num_cache_nodes      = var.elasticache_nodes
  parameter_group_name = var.elasticache_parameter_group_name
  security_group_ids   = [aws_security_group.redis[0].id]
  subnet_group_name    = var.cache_subnet_group != "" ? var.cache_subnet_group : aws_elasticache_subnet_group.cache-subnet[0].id
  apply_immediately    = true
  maintenance_window   = "tue:06:00-tue:07:00"

  tags = merge(var.extra_tags, {
    Name = "${local.name_prefix}-${var.elasticache_engine}"
    role = "redis"
  })
}

resource "aws_elasticache_subnet_group" "cache-subnet" {
  name        = replace("${local.name_prefix}-cache", var.nameregex, "")
  count       = var.cache_subnet_group == "" && var.create_elasticache ? 1 : 0
  description = "redis cache subnet for ${var.project}-${var.env} ${var.vpc_id}"
  subnet_ids  = var.private_subnets_ids
}

output "elasticache_address" {
  value = try(aws_elasticache_cluster.redis[0].cache_nodes[0].address, "")
}

output "elasticache_cluster_id" {
  value = try(local.elasticache_cluster_id, "")
}
