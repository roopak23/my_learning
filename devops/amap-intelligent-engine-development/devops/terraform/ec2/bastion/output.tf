output "ec2_test_instance_id" {
  description = "ec2 test instance"
  value       = aws_instance.test.id
}

output "ec2_test_private_dns" {
  description = "ec2 test instance"
  value       = aws_instance.test.private_dns
}

output "ec2_test_private_ip" {
  description = "ec2 test instance"
  value       = aws_instance.test.private_ip
}

output "test_sec_group_id" {
  description = "ec2 test instance"
  value       = aws_security_group.ec2_test_sg.id
}
