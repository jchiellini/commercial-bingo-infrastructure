#  __     ______   ____
#  \ \   / /  _ \ / ___|
#   \ \ / /| |_) | |
#    \ V / |  __/| |___
#     \_/  |_|    \____|

data "aws_vpc" "vpc" {
  id = var.vpc_id
}


#   ___       _                       _      ____       _
#  |_ _|_ __ | |_ ___ _ __ _ __   ___| |_   / ___| __ _| |_ _____      ____ _ _   _
#   | || '_ \| __/ _ \ '__| '_ \ / _ \ __| | |  _ / _` | __/ _ \ \ /\ / / _` | | | |
#   | || | | | ||  __/ |  | | | |  __/ |_  | |_| | (_| | ||  __/\ V  V / (_| | |_| |
#  |___|_| |_|\__\___|_|  |_| |_|\___|\__|  \____|\__,_|\__\___| \_/\_/ \__,_|\__, |
#                                                                             |___/

data "aws_internet_gateway" "igw" {
  internet_gateway_id = var.igw_id
}


#   ____        _                _
#  / ___| _   _| |__  _ __   ___| |_ ___
#  \___ \| | | | '_ \| '_ \ / _ \ __/ __|
#   ___) | |_| | |_) | | | |  __/ |_\__ \
#  |____/ \__,_|_.__/|_| |_|\___|\__|___/

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private_subnets" {
  count = 2

  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + var.private_subnet_range)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name       = "${var.app} Private Subnet ${count.index + 1}"
    CostCenter = var.app
  }
}

resource "aws_subnet" "public_subnets" {
  count = 2

  vpc_id            = data.aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, count.index + var.public_subnet_range)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name       = "${var.app} Public Subnet ${count.index + 1}"
    CostCenter = var.app
    Access     = "public"
  }
}


#   _____ ___ ____
#  | ____|_ _|  _ \
#  |  _|  | || |_) |
#  | |___ | ||  __/
#  |_____|___|_|

resource "aws_eip" "eip" {
  count      = 2
  depends_on = [data.aws_internet_gateway.igw]

  vpc = true

  tags = {
    Name       = "${var.app} EIP ${count.index + 1}"
    CostCenter = var.app
  }
}

#   _   _    _  _____    ____       _
#  | \ | |  / \|_   _|  / ___| __ _| |_ _____      ____ _ _   _
#  |  \| | / _ \ | |   | |  _ / _` | __/ _ \ \ /\ / / _` | | | |
#  | |\  |/ ___ \| |   | |_| | (_| | ||  __/\ V  V / (_| | |_| |
#  |_| \_/_/   \_\_|    \____|\__,_|\__\___| \_/\_/ \__,_|\__, |
#                                                         |___/

resource "aws_nat_gateway" "ng" {
  count = 2
  subnet_id = aws_subnet.public_subnets[count.index].id

  depends_on    = [data.aws_internet_gateway.igw]
  allocation_id = aws_eip.eip.*.id[count.index]

  tags = {
    Name       = "${var.app} NAT Gateway ${count.index + 1}"
    CostCenter = var.app
  }
}

#   ____             _         _____     _     _
#  |  _ \ ___  _   _| |_ ___  |_   _|_ _| |__ | | ___  ___
#  | |_) / _ \| | | | __/ _ \   | |/ _` | '_ \| |/ _ \/ __|
#  |  _ < (_) | |_| | ||  __/   | | (_| | |_) | |  __/\__ \
#  |_| \_\___/ \__,_|\__\___|   |_|\__,_|_.__/|_|\___||___/

resource "aws_route_table" "rt_public_subnet" {
  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.igw.id
  }

  tags = {
    Name       = "${var.app} Public Route Table"
    CostCenter = var.app
  }
}

resource "aws_route_table_association" "rt_public_subnet" {
  count = 2

  subnet_id      = aws_subnet.public_subnets.*.id[count.index]
  route_table_id = aws_route_table.rt_public_subnet.id
}

resource "aws_route_table" "rt_private_subnet" {
  count = 2

  vpc_id = data.aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ng.*.id[count.index]
  }

  tags = {
    Name       = "${var.app} Private Route Table ${count.index + 1}"
    CostCenter = var.app
  }
}

resource "aws_route_table_association" "rt_private_subnet" {
  count = 2

  subnet_id      = aws_subnet.private_subnets.*.id[count.index]
  route_table_id = aws_route_table.rt_private_subnet.*.id[count.index]
}
