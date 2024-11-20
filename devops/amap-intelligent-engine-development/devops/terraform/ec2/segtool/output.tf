output "ec2_segtool_instance_id" {
  description = "ec2 segtool instance"
  value       = aws_instance.segtool.id
}

output "ec2_segtool_private_dns" {
  description = "ec2 segtool instance"
  value       = aws_instance.segtool.private_dns
}

output "ec2_segtool_private_ip" {
  description = "ec2 segtool instance"
  value       = aws_instance.segtool.private_ip
}

output "segtool_sec_group_id" {
  description = "ec2 segtool instance"
  value       = aws_security_group.ec2_segtool_sg.id
}
