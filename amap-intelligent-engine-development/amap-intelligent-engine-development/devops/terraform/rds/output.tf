output "rds" {
    description = "rds info"
    value = aws_db_instance.rds.endpoint
}


output "id" {
    description = "rds info"
    value = aws_db_instance.rds.id
}

output "instance_classs" {
    description = "rds info"
    value = aws_db_instance.rds.instance_class
}


output "rds_engine" {
    description = "rds info"
    value = aws_db_instance.rds.engine_version_actual
}

output "rds_subnet" {
    description = "amap-dm-rds-subnet"
    value = aws_db_subnet_group.rds_subnet.name
}

output "rds_security_group_id" {
    description = "amap-dm-rds-subnet"
    value = aws_security_group.rds_sg.id
}
