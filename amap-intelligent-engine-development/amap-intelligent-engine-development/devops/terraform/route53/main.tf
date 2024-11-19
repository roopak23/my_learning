


resource "aws_route53_zone" "private_site" {
 name = "${var.route_53_private_site}"
 tags = {
   Name = "${var.route_53_private_site}"
   Environment = "${var.env}"
 }
 vpc {
   vpc_id      = var.vpc_id
   vpc_region  = var.aws_region
 }
}

# resource "aws_route53_record" "private_site" {
#   count   = var.nlb_internal != "" ? 1 : 0
#   name    = var.private_site
#   zone_id = var.zone_id
#   type    = "A"
#   alias {
#     name                   = var.nlb_internal.dns_name
#     zone_id                = var.nlb_internal.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_route53_record" "public_site" {
#   count   = var.alb_internal != "" ? 1 : 0
#   zone_id = var.zone_id
#   type    = "A"
#   alias {
#     name                   = var.alb_internal.dns_name
#     zone_id                = var.alb_internal.zone_id
#     evaluate_target_health = true
#   }
# }


# resource "aws_route53_record" "segtool_site" {
#   count   = var.alb_external != "" ? 1 : 0
#   zone_id = var.zone_id
#   name    = var.segtool_site
#   type    = "A"
#   records = [var.alb_external]
#   ttl     = 300
# }
