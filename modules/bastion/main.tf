#   ____                       _ _            ____
#  / ___|  ___  ___ _   _ _ __(_) |_ _   _   / ___|_ __ ___  _   _ _ __
#  \___ \ / _ \/ __| | | | '__| | __| | | | | |  _| '__/ _ \| | | | '_ \
#   ___) |  __/ (__| |_| | |  | | |_| |_| | | |_| | | | (_) | |_| | |_) |
#  |____/ \___|\___|\__,_|_|  |_|\__|\__, |  \____|_|  \___/ \__,_| .__/
#                                    |___/                        |_|

resource "aws_security_group" "bastion_sg" {
  name   = "${var.environment}-${var.app}-bastion"
  vpc_id = var.vpc_id

  description = "Allows DB access to bastion host"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    description      = "Allow inbound connection from SSM"
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    description      = ""
    from_port        = 22
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 22
  }

  egress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    description      = "Allow outbound connection to RDS"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 5432
  }

  egress {
    cidr_blocks = [
      "0.0.0.0/0",
    ]
    description      = "VPC endpoints"
    from_port        = 443
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups  = []
    self             = false
    to_port          = 443
  }

  tags = {
    Name       = "${var.app} Bastion SG"
    CostCenter = var.app
  }
}

#   ____       _
#  |  _ \ ___ | | ___
#  | |_) / _ \| |/ _ \
#  |  _ < (_) | |  __/
#  |_| \_\___/|_|\___|

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "bastion_role" {
  name                = "EC2-RDS-AccessRole-${var.app}-${var.environment}"
  description         = "Allows EC2 instances to call AWS services on your behalf"
  assume_role_policy  = file("./policies/ssm_role.json")
  managed_policy_arns = [data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn]

  tags = {
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_iam_instance_profile" "iam_profile" {
  name = "${var.app}-${var.environment}-bastion-profile"
  role = aws_iam_role.bastion_role.name

  tags = {
    CostCenter  = var.app
    Environment = var.environment
  }
}

#   _____ ____ ____
#  | ____/ ___|___ \
#  |  _|| |     __) |
#  | |__| |___ / __/
#  |_____\____|_____|

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }
}

resource "aws_instance" "bastion" {
  ami                  = "ami-0b5eea76982371e91" // data.aws_ami.amazon_linux_2.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.iam_profile.name

  network_interface {
    network_interface_id = aws_network_interface.bastion_network.id
    device_index         = 0
  }

  depends_on = [
    aws_iam_instance_profile.iam_profile,
    aws_network_interface.bastion_network
  ]

  tags = {
    Name       = "${var.app} Bastion"
    CostCenter = var.app
  }
}

resource "aws_network_interface" "bastion_network" {
  subnet_id = var.subnets[0]

  security_groups = [
    aws_security_group.bastion_sg.id
  ]

  depends_on = [
    aws_security_group.bastion_sg
  ]

  tags = {
    Name       = "${var.app} Bastion Host Network"
    CostCenter = var.app
  }
}

#  __     ______   ____   _____           _             _       _
#  \ \   / /  _ \ / ___| | ____|_ __   __| |_ __   ___ (_)_ __ | |_ ___
#   \ \ / /| |_) | |     |  _| | '_ \ / _` | '_ \ / _ \| | '_ \| __/ __|
#    \ V / |  __/| |___  | |___| | | | (_| | |_) | (_) | | | | | |_\__ \
#     \_/  |_|    \____| |_____|_| |_|\__,_| .__/ \___/|_|_| |_|\__|___/
#                                          |_|

//terraform import -var-file="vars/dev.tfvars" module.bastion.aws_vpc_endpoint.vpc_endpoint_ssm vpce-0f27c0e75b6f6d15b
//terraform import -var-file="vars/dev.tfvars" module.bastion.aws_vpc_endpoint.vpc_endpoint_ssmmesages vpce-0f520b83411a899c2
//terraform import -var-file="vars/dev.tfvars" module.bastion.aws_vpc_endpoint.vpc_endpoint_ec2mesages vpce-01127794e0e40a988

resource "aws_vpc_endpoint" "vpc_endpoint_ssm" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.bastion_sg.id,
  ]

  subnet_ids = var.subnets

  # depends_on = [aws_instance.bastion]

  tags = {
    Name       = "${var.app} VPC Endpoint SSM"
    CostCenter = var.app
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint_ssmmesages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.bastion_sg.id,
  ]

  subnet_ids = var.subnets

  # depends_on = [aws_instance.bastion]

  tags = {
    Name       = "${var.app} VPC Endpoint SSMMessages"
    CostCenter = var.app
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint_ec2mesages" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.bastion_sg.id,
  ]

  subnet_ids = var.subnets

  # depends_on = [aws_instance.bastion]

  tags = {
    Name       = "${var.app} VPC Endpoint EC2Messages"
    CostCenter = var.app
  }
}
