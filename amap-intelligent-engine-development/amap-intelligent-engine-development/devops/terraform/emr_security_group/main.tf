### service access group
resource "aws_security_group" "emr_service_access_sg" {
  name        = "${var.prefix}-emr_service_access_sg"
  description = "Created based on default  ElasticMapReduce-ServiceAccess with limited ports "
  vpc_id      = var.vpc_id

}

resource "aws_security_group_rule" "emr_mp_service_sgr" {
  description              = "Ingress for ElasticMapReduce-Master-Private"
  type                     = "ingress"
  from_port                = 9443
  to_port                  = 9443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_master_private_sg.id
  security_group_id        = aws_security_group.emr_service_access_sg.id
}

resource "aws_security_group_rule" "emr_service_mp_sgr" {
  description              = "Egress to ElasticMapReduce-Master-Private"
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_master_private_sg.id
  security_group_id        = aws_security_group.emr_service_access_sg.id
}


resource "aws_security_group_rule" "emr_service_ms_sgr" {
  description              = "Egress to ElasticMapReduce-Slave-Privatee"
  type                     = "egress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_slave_private_sg.id
  security_group_id        = aws_security_group.emr_service_access_sg.id
}

### master private  group
resource "aws_security_group" "emr_master_private_sg" {
  name        = "${var.prefix}-emr-master-private-sg"
  description = "Created based on default  ElasticMapReduce-Master-Private with limited ports "
  vpc_id      = var.vpc_id
}


resource "aws_security_group_rule" "emr_mp_mp_icmp_sgr" {
  description       = "Ingress for ElasticMapReduce-Master-Private from Master-Private"
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  self              = true
  security_group_id = aws_security_group.emr_master_private_sg.id
}


resource "aws_security_group_rule" "emr_sp_mp_icmp_sgr" {
  description              = "Ingress for ElasticMapReduce-Master-Private from Slave-Private"
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.emr_slave_private_sg.id
  security_group_id        = aws_security_group.emr_master_private_sg.id

}


resource "aws_security_group_rule" "emr_mp_mp_udp_sgr" {
  description       = "Ingress for ElasticMapReduce-Master-Private from Master-Private"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.emr_master_private_sg.id
}


resource "aws_security_group_rule" "emr_sp_mp_udp_sgr" {
  description              = "Ingress for ElasticMapReduce-Master-Private from Slave-Private"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.emr_slave_private_sg.id
  security_group_id        = aws_security_group.emr_master_private_sg.id

}

resource "aws_security_group_rule" "emr_sr_mp_tcp_sgr" {
  description              = "Ingress for ElasticMapReduce-Master-Private from Service-Private"
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_service_access_sg.id
  security_group_id        = aws_security_group.emr_master_private_sg.id

}

resource "aws_security_group_rule" "emr_mp_mp_tcp_sgr" {
  description       = "Ingress for ElasticMapReduce-Master-Private from Master-Private"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.emr_master_private_sg.id
}

resource "aws_security_group_rule" "emr_sp_mp_tcp_sgr" {
  description              = "Ingress for ElasticMapReduce-Master-Private from Slave-Private"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_slave_private_sg.id
  security_group_id        = aws_security_group.emr_master_private_sg.id
}

resource "aws_security_group_rule" "emr_mp_vpc_all_sgr" {
  description       = "Egress to VPC"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.emr_master_private_sg.id

}

resource "aws_security_group_rule" "emr_mp_its_all_sgr" {
  description       = "Egress to internet"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.emr_master_private_sg.id

}

## czy potrzebujemy to??
resource "aws_security_group_rule" "emr_mp_it_all_sgr" {
  description       = "Egress to internet"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.emr_master_private_sg.id

}



###  slave private  group
resource "aws_security_group" "emr_slave_private_sg" {
  name        = "${var.prefix}-emr-slave-private-sg"
  description = "Created based on default  ElasticMapReduce-Master-Private with limited ports "
  vpc_id      = var.vpc_id

}

resource "aws_security_group_rule" "emr_sp_sp_icmp_sgr" {
  description       = "Ingress for ElasticMapReduce-Slave-Private from Slave-Private"
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  self              = true
  security_group_id = aws_security_group.emr_slave_private_sg.id
}

resource "aws_security_group_rule" "emr_mp_sp_icmp_sgr" {
  description              = "Ingress for ElasticMapReduce-Slave-Private from Master-Private"
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "icmp"
  source_security_group_id = aws_security_group.emr_master_private_sg.id
  security_group_id        = aws_security_group.emr_slave_private_sg.id

}

resource "aws_security_group_rule" "emr_sp_sp_udp_sgr" {
  description       = "Ingress for ElasticMapReduce-Slave-Private from Slave-Private"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "udp"
  self              = true
  security_group_id = aws_security_group.emr_slave_private_sg.id
}

resource "aws_security_group_rule" "emr_mp_sp_udp_sgr" {
  description              = "Ingress for ElasticMapReduce-Slave-Private from Master-Private"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "udp"
  source_security_group_id = aws_security_group.emr_master_private_sg.id
  security_group_id        = aws_security_group.emr_slave_private_sg.id

}

resource "aws_security_group_rule" "emr_sr_sp_tcp_sgr" {
  description              = "Ingress for ElasticMapReduce-Slave-Private from Service-Private"
  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_service_access_sg.id
  security_group_id        = aws_security_group.emr_slave_private_sg.id

}

resource "aws_security_group_rule" "emr_sp_sp_tcp_sgr" {
  description       = "Ingress for ElasticMapReduce-Slave-Private from Slave-Private"
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.emr_slave_private_sg.id
}

resource "aws_security_group_rule" "emr_mp_sp_tcp_sgr" {
  description              = "Ingress for ElasticMapReduce-Slave-Private from Master-Private"
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.emr_master_private_sg.id
  security_group_id        = aws_security_group.emr_slave_private_sg.id
}

resource "aws_security_group_rule" "emr_sp_vpc_all_sgr" {
  description       = "Egress to VPC"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = aws_security_group.emr_slave_private_sg.id
}

resource "aws_security_group_rule" "emr_sp_its_all_sgr" {
  description       = "Egress to internet"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.emr_slave_private_sg.id

}

## czy potrzebujemy to??
resource "aws_security_group_rule" "emr_sp_it_all_sgr" {
  description       = "Egress to internet"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.emr_slave_private_sg.id

}


#additional sg
resource "aws_security_group" "emr_additional_sg" {
  name   = "${var.prefix}-emr-additional-sg"
  vpc_id = var.vpc_id

}

resource "aws_security_group_rule" "emr_additional_rule_eks" {
  description              = "Allow Airflow pods to communicate with EMR Cluster"
  security_group_id        = aws_security_group.emr_additional_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = var.eks_security_groups
}



resource "aws_security_group_rule" "emr_additional_rule_vpn" {
  for_each          = { for index, rule in var.emr_vpn_additional_rules : rule.port => rule }
  description       = each.value.descritpion
  security_group_id = aws_security_group.emr_additional_sg.id
  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  cidr_blocks       = var.citrix_cidrs
}

