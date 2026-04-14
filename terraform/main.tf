# ============================================
# PRIMARY REGION (us-east-1)
# ============================================
module "primary" {
  source = "./modules/region"
  providers = {
    aws = aws.primary
  }
  region_name    = var.primary_region
  environment    = var.environment
  vpc_cidr       = "10.0.0.0/16"
  instance_type  = var.instance_type
  key_name       = var.key_name
  alb_priority   = 1
}

# ============================================
# SECONDARY REGION (us-west-2)
# ============================================
module "secondary" {
  source = "./modules/region"
  providers = {
    aws = aws.secondary
  }
  region_name    = var.secondary_region
  environment    = var.environment
  vpc_cidr       = "10.1.0.0/16"
  instance_type  = var.instance_type
  key_name       = var.key_name
  alb_priority   = 2
}

# ============================================
# GLOBAL: Route53 Latency + Failover Routing
# ============================================
data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

# Latency records – Route53 automatically routes to lowest latency
resource "aws_route53_record" "app_latency" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.primary.alb_dns_name
    zone_id                = module.primary.alb_zone_id
    evaluate_target_health = true
  }
  set_identifier = "primary-latency"
  latency_routing_policy {
    region = var.primary_region
  }
}

resource "aws_route53_record" "app_latency_secondary" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.secondary.alb_dns_name
    zone_id                = module.secondary.alb_zone_id
    evaluate_target_health = true
  }
  set_identifier = "secondary-latency"
  latency_routing_policy {
    region = var.secondary_region
  }
}

# Failover record – primary active, secondary standby (for manual/automated failover)
resource "aws_route53_record" "app_failover_primary" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "failover.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.primary.alb_dns_name
    zone_id                = module.primary.alb_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "PRIMARY"
  }
  set_identifier = "primary-failover"
}

resource "aws_route53_record" "app_failover_secondary" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "failover.${var.domain_name}"
  type    = "A"
  alias {
    name                   = module.secondary.alb_dns_name
    zone_id                = module.secondary.alb_zone_id
    evaluate_target_health = true
  }
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier = "secondary-failover"
}

# ============================================
# GLOBAL: CloudWatch Dashboard & Alarms
# ============================================
resource "aws_cloudwatch_dashboard" "network_dashboard" {
  dashboard_name = "MultiRegionNetwork"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.primary.alb_arn_suffix, { stat = "p95", region = var.primary_region }],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.secondary.alb_arn_suffix, { stat = "p95", region = var.secondary_region }]
          ],
          period = 60,
          stat   = "Average",
          region = var.primary_region,
          title  = "Latency (p95) - Primary vs Secondary"
        }
      },
      {
        type = "alarm",
        properties = {
          alarms = [aws_cloudwatch_metric_alarm.high_latency_primary.arn, aws_cloudwatch_metric_alarm.high_latency_secondary.arn],
          title  = "High Latency Alarms"
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "high_latency_primary" {
  alarm_name          = "primary-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.5
  alarm_description   = "Primary region ALB latency >500ms"
  dimensions = {
    LoadBalancer = module.primary.alb_arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "high_latency_secondary" {
  provider = aws.secondary
  alarm_name          = "secondary-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0.5
  dimensions = {
    LoadBalancer = module.secondary.alb_arn_suffix
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_sns_topic" "alerts" {
  name = "network-failover-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "your-email@example.com"  # Change this
}
