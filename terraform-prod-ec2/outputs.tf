output "public_ips" {
  value = aws_instance.ec2[*].public_ip
}

output "ssh_commands" {
  value = [
    for ip in aws_instance.ec2[*].public_ip :
    "ssh ubuntu@${ip}"
  ]
}
