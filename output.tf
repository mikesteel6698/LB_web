output "private_ip_pro_1" {
  value = aws_instance.pro_1.private_ip
}

output "public_ip_pro_1" {
  value = aws_instance.pro_1.public_ip
}

output "private_ip_pro_2" {
  value = aws_instance.pro_2[*].private_ip
}

output "public_ip_pro_2" {
  value = aws_instance.pro_2[*].public_ip
}

output "name-servers" {
  value = aws_route53_zone.pro_zone.name_servers
}