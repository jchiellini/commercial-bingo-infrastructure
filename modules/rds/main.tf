#   ____                       _ _            ____
#  / ___|  ___  ___ _   _ _ __(_) |_ _   _   / ___|_ __ ___  _   _ _ __
#  \___ \ / _ \/ __| | | | '__| | __| | | | | |  _| '__/ _ \| | | | '_ \
#   ___) |  __/ (__| |_| | |  | | |_| |_| | | |_| | | | (_) | |_| | |_) |
#  |____/ \___|\___|\__,_|_|  |_|\__|\__, |  \____|_|  \___/ \__,_| .__/
#                                    |___/                        |_|

resource "aws_security_group" "security_group" {
  name   = "${var.environment}-${var.app}-rds"
  vpc_id = var.vpc_id

  description = "${var.environment}-${var.app} RDS Security group"

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = var.cidr_blocks
    description = "Allows access to VPC"
  }

  ingress {
    cidr_blocks      = []
    description      = "Allows access to Bastion"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups = [
      var.bastion_sg
    ]
    self    = false
    to_port = 5432
  }

  ingress {
    cidr_blocks      = []
    description      = "Allows access to Lambdas"
    from_port        = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids  = []
    protocol         = "tcp"
    security_groups = [
      var.lambda_sg
    ]
    self    = false
    to_port = 5432
  }

  ingress {
    protocol         = "tcp"
    cidr_blocks      = [var.vpc_cidr_block]
    from_port        = 5432
    to_port          = 5432
    description      = "Allows access"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = var.cidr_blocks
    description = "Allows access to VPC"
  }

  depends_on = [
    var.lambda_sg
  ]

  tags = {
    Name        = "${var.environment}-${var.app} RDS Security group"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#   ____  ____  ____
#  |  _ \|  _ \/ ___|
#  | |_) | | | \___ \
#  |  _ <| |_| |___) |
#  |_| \_\____/|____/

data "aws_rds_engine_version" "pg" {
  engine  = "postgres"
  version = "13.8"
}


module "db_rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.environment}-${var.app}"

  engine               = data.aws_rds_engine_version.pg.engine
  engine_version       = data.aws_rds_engine_version.pg.version
  family               = "postgres13"
  major_engine_version = "13"
  instance_class       = "db.t3.small"

  allocated_storage     = 50
  max_allocated_storage = 100
  storage_encrypted     = true

  db_name                = var.db_name
  username               = "root"
  port                   = 5432
  create_random_password = true
  copy_tags_to_snapshot  = true

  multi_az               = true
  create_db_subnet_group = true
  subnet_ids             = var.private_subnets
  vpc_security_group_ids = [aws_security_group.security_group.id]

  maintenance_window              = "Sat:00:00-Sat:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period   = 7
  skip_final_snapshot       = true
  deletion_protection       = true
  create_db_parameter_group = false

  tags = {
    Name        = "${var.environment}-${var.app} RDS"
    CostCenter  = var.app
    Environment = var.environment
  }
}

#   ____                     _
#  / ___|  ___  ___ _ __ ___| |_ ___
#  \___ \ / _ \/ __| '__/ _ \ __/ __|
#   ___) |  __/ (__| | |  __/ |_\__ \
#  |____/ \___|\___|_|  \___|\__|___/

resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.app}/${var.environment}/database/secrets"

  tags = {
    Name        = "${var.app}-${var.environment} DB Secrets"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  depends_on = [
    module.db_rds.db_instance_id
  ]
  secret_string = jsonencode({
    "username" : "${module.db_rds.db_instance_username}",
    "password" : "${module.db_rds.db_instance_password}",
  })
}

#   ____  ____  ____
#  |  _ \|  _ \/ ___|   _ __  _ __ _____  ___   _
#  | |_) | | | \___ \  | '_ \| '__/ _ \ \/ / | | |
#  |  _ <| |_| |___) | | |_) | | | (_) >  <| |_| |
#  |_| \_\____/|____/  | .__/|_|  \___/_/\_\\__, |
#                      |_|                  |___/

resource "aws_iam_policy" "rds_proxy_policy" {
  name = "${var.environment}-${var.app}-rds-proxy-policy"

  policy = file("./policies/rds_proxy_policy.json")
  tags = {
    Name        = "${var.environment}-${var.app} RDS Proxy Policy"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_iam_role" "rds_proxy_role" {
  name                = "${var.environment}-${var.app}-rds-proxy-role"
  assume_role_policy  = file("./policies/rds_proxy_role.json")
  managed_policy_arns = [aws_iam_policy.rds_proxy_policy.arn]

  tags = {
    Name        = "${var.environment}-${var.app} RDS Proxy Role"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_db_proxy" "rds_proxy" {
  name                   = "${var.environment}-${var.app}"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 5400
  require_tls            = false
  role_arn               = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids = [aws_security_group.security_group.id, var.lambda_sg]
  vpc_subnet_ids         = var.private_subnets

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_secret.arn
  }

  depends_on = [
    module.db_rds.db_instance_id,
    aws_security_group.security_group,
    var.lambda_sg,
  ]

  tags = {
    Name        = "${var.environment}-${var.app} RDS Proxy"
    CostCenter  = var.app
    Environment = var.environment
  }
}

resource "aws_db_proxy_default_target_group" "rds_proxy_target_group" {
  db_proxy_name = aws_db_proxy.rds_proxy.name

  depends_on = [
    aws_db_proxy.rds_proxy
  ]

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "target" {
  db_instance_identifier = "${var.environment}-${var.app}"
  db_proxy_name          = aws_db_proxy.rds_proxy.name
  target_group_name      = aws_db_proxy_default_target_group.rds_proxy_target_group.name

  depends_on = [
    aws_db_proxy.rds_proxy,
    module.db_rds.db_instance_id
  ]
}
