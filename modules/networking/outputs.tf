output "vpc_id" {
  value = data.aws_vpc.vpc.id
}

output "private_subnets" {
  value = tolist(aws_subnet.private_subnets.*.id)
}

output "cidr_blocks" {
  value = tolist(aws_subnet.private_subnets.*.cidr_block)
}
