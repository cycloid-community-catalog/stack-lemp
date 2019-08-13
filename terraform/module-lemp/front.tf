###

# front

###

resource "aws_security_group" "front" {
  name        = "${var.project}-front-${var.env}"
  description = "Front ${var.env} for ${var.project}"
  vpc_id      = var.vpc_id

  # Allow to get myeasyapi nginx, openapi nginx, mypages nginx
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-front.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "cycloid.io" = "true"
    Name         = "${var.project}-front-${var.env}"
    env          = var.env
    project      = var.project
    role         = "front"
  }
}

###
# aws_launch_template
###

resource "aws_launch_template" "front" {
  name_prefix = "${var.project}_front_${var.env}_version_"

  image_id      = local.image_id
  instance_type = var.front_type
  user_data     = base64encode(data.template_file.user_data_front.rendered)
  key_name      = var.keypair_name

  /*
  instance_market_options {
    market_type = "spot"

    spot_options {
      spot_instance_type = "one-time"
      max_price          = "${var.front_spot_price}"
    }
  }
  */

  network_interfaces {
    associate_public_ip_address = var.front_associate_public_ip_address
    delete_on_termination       = true

    security_groups = compact(
      [
        var.bastion_sg_allow,
        aws_security_group.front.id,
        var.metrics_sg_allow,
      ],
    )
  }
  lifecycle {
    create_before_destroy = true
  }
  ebs_optimized = var.front_ebs_optimized
  iam_instance_profile {
    name = aws_iam_instance_profile.front_profile.name
  }
  tags = {
    "cycloid.io" = "true"
    Name         = "${var.project}-fronttemplate-${var.env}"
    client       = var.customer
    env          = var.env
    project      = var.project
    role         = "fronttemplate"
  }
  tag_specifications {
    resource_type = "instance"

    tags = {
      "cycloid.io" = "true"
      Name         = "${var.project}-front-${var.env}"
      client       = var.customer
      env          = var.env
      project      = var.project
      role         = "front"
    }
  }
  tag_specifications {
    resource_type = "volume"

    tags = {
      "cycloid.io" = "true"
      Name         = "${var.project}-front-${var.env}"
      client       = var.customer
      env          = var.env
      project      = var.project
      role         = "front"
    }
  }
  block_device_mappings {
    device_name = "xvda"

    ebs {
      volume_size           = var.front_disk_size
      volume_type           = var.front_disk_type
      delete_on_termination = true
    }
  }
}

###

# ASG

###

# Workaround to have 80 or 443 optional
locals {
  target_group_arns = compact(
    concat(
      aws_alb_target_group.front-80.*.arn,
      aws_alb_target_group.front-443.*.arn,
    ),
  )
}

resource "aws_cloudformation_stack" "front" {
  name = "${var.project}-front-${var.env}"

  template_body = <<EOF
{
  "Resources": {
    "Fronts${var.env}": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "AvailabilityZones": ${jsonencode(var.zones)},
        "VPCZoneIdentifier": ${jsonencode(var.private_subnets_ids)},
        "LaunchTemplate": {
            "LaunchTemplateId": "${aws_launch_template.front.id}",
            "Version" : "${aws_launch_template.front.latest_version}"
        },
        "MaxSize": "${var.front_asg_max_size}",
        "DesiredCapacity" : "${var.front_count}",
        "MinSize": "${var.front_asg_min_size}",
        "TerminationPolicies": ["OldestLaunchConfiguration", "NewestInstance"],
        "HealthCheckType": "ELB",
        "TargetGroupARNs": ["${join("\", \"", local.target_group_arns)}"],
        "HealthCheckGracePeriod": 600,
        "Tags" : [
          { "Key" : "Name", "Value" : "${var.project}-front-${var.short_region[var.aws_region]}-${var.env}", "PropagateAtLaunch" : "true" },
          { "Key" : "client", "Value" : "${var.customer}", "PropagateAtLaunch" : "true" },
          { "Key" : "env", "Value" : "${var.env}", "PropagateAtLaunch" : "true" },
          { "Key" : "project", "Value" : "${var.project}", "PropagateAtLaunch" : "true" },
          { "Key" : "role", "Value" : "front", "PropagateAtLaunch" : "true" },
          { "Key" : "cycloid.io", "Value" : "true", "PropagateAtLaunch" : "true" }
        ]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "${var.front_update_min_in_service}",
          "MinSuccessfulInstancesPercent": "50",
          "SuspendProcesses": ["ScheduledActions"],
          "MaxBatchSize": "2",
          "PauseTime": "PT8M",
          "WaitOnResourceSignals": "true"
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "The name of the auto scaling group",
       "Value": {"Ref": "Fronts${var.env}"}
    }
  }
}
EOF

}

###

# ALB

###

resource "aws_security_group" "alb-front" {
  name = "${var.project}-alb-front-${var.env}"
  description = "Front ${var.env} for ${var.project}"
  vpc_id = var.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-alb-front-${var.env}"
    client = var.customer
    env = var.env
    project = var.project
    "cycloid.io" = "true"
  }
}

# TargetGroup for ALBs
resource "aws_alb_target_group" "front-80" {
  name = "${var.project}-front80-${var.env}"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = var.application_health_check_path
    matcher = var.application_health_check_matcher
    timeout = var.application_path_health_timeout
    interval = var.application_path_health_interval
  }

  stickiness {
    type = "lb_cookie"
    enabled = true
  }
}

# TargetGroup for ALBs
resource "aws_alb_target_group" "front-443" {
  count = var.application_ssl_cert != "" ? 1 : 0
  name = "${var.project}-front443-${var.env}"
  port = 443
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = var.application_health_check_path
    matcher = var.application_health_check_matcher
    timeout = var.application_path_health_timeout
    interval = var.application_path_health_interval
  }

  stickiness {
    type = "lb_cookie"
    enabled = true
  }
}

#
# Create a loadbalancer
#

resource "aws_alb" "front" {
  name = "${var.project}-front-${var.env}"
  security_groups = [aws_security_group.alb-front.id]
  subnets = var.public_subnets_ids

  enable_cross_zone_load_balancing = true
  idle_timeout = 600

  tags = {
    Name = "${var.customer}-${var.project}-front-${var.short_region[var.aws_region]}-${var.env}"
    client = var.customer
    role = "front"
    env = var.env
    project = var.project
    "cycloid.io" = "true"
  }
}

# 443 by defaut to front
resource "aws_alb_listener" "front-443" {
  count = var.application_ssl_cert != "" ? 1 : 0
  load_balancer_arn = aws_alb.front.arn
  port = "443"
  protocol = "HTTPS"
  certificate_arn = var.application_ssl_cert
  ssl_policy = var.application_ssl_policy

  default_action {
    target_group_arn = aws_alb_target_group.front-80.arn
    type = "forward"
  }
}

# 80 default to front
resource "aws_alb_listener" "front-80" {
  load_balancer_arn = aws_alb.front.arn
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.front-80.arn
    type = "forward"
  }
}

#####
# Cloudwatch autoscaling
#####

resource "aws_autoscaling_policy" "front-scale-up" {
  name = "${var.project}-front-scale-up-${var.env}"
  scaling_adjustment = var.front_asg_scale_up_scaling_adjustment
  adjustment_type = "ChangeInCapacity"
  cooldown = var.front_asg_scale_up_cooldown
  autoscaling_group_name = aws_cloudformation_stack.front.outputs["AsgName"]
}

resource "aws_cloudwatch_metric_alarm" "front-scale-up" {
  alarm_name = "${var.project}-front-scale-up-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = var.front_asg_scale_up_threshold

  dimensions = {
    AutoScalingGroupName = aws_cloudformation_stack.front.outputs["AsgName"]
  }

  alarm_description = "This metric monitor ec2 cpu utilization on ${var.project} ${var.env}"
  alarm_actions = [aws_autoscaling_policy.front-scale-up.arn]
}

resource "aws_autoscaling_policy" "front-scale-down" {
  name = "${var.project}-front-scale-down-${var.env}"
  scaling_adjustment = var.front_asg_scale_down_scaling_adjustment
  adjustment_type = "ChangeInCapacity"
  cooldown = var.front_asg_scale_down_cooldown
  autoscaling_group_name = aws_cloudformation_stack.front.outputs["AsgName"]
}

resource "aws_cloudwatch_metric_alarm" "front-scale-down" {
  alarm_name = "${var.project}-front-scale-down-${var.env}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = var.front_asg_scale_down_threshold

  dimensions = {
    AutoScalingGroupName = aws_cloudformation_stack.front.outputs["AsgName"]
  }

  alarm_description = "This metric monitor ec2 cpu utilization on ${var.project} ${var.env}"
  alarm_actions = [aws_autoscaling_policy.front-scale-down.arn]
}
