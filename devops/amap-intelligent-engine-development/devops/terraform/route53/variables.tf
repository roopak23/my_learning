variable "vpc_id" {
    description = "vpc id to use"
}

variable route_53_private_site {
    description = "domain name"
}

# variable "prefix" {
#     description = "env"
# }

# variable "route53_internal_loadbalancer" {
#     description = "internal loadbalancer name"
# }

variable "env" {
    description = "environment"
}

variable "aws_region" {
    description = "aws region"
}

# variable "route53_internal_loadbalancer_hostez_zone" {
#     description = "hosted zone id of the load balancer"
# }

# variable "zone_id" {
#     description = "EMR static IP"
# }

# variable "private_site" {
#     description = "EMR static IP"
# }


# variable "public_site" {
#     description = "EMR static IP"
# }

# variable "segtool_site" {
#     description = "EMR static IP"
# }



# variable "nlb_internal" {
#     description = "EMR static IP"
# }


# variable "alb_internal" {
#     description = "EMR static IP"
# }

# variable "alb_external" {
#     description = "EMR static IP"
# }