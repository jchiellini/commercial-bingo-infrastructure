#   ____                       _ _            ____
#  / ___|  ___  ___ _   _ _ __(_) |_ _   _   / ___|_ __ ___  _   _ _ __
#  \___ \ / _ \/ __| | | | '__| | __| | | | | |  _| '__/ _ \| | | | '_ \
#   ___) |  __/ (__| |_| | |  | | |_| |_| | | |_| | | | (_) | |_| | |_) |
#  |____/ \___|\___|\__,_|_|  |_|\__|\__, |  \____|_|  \___/ \__,_| .__/
#                                    |___/                        |_|

resource "aws_security_group" "lambda_sg" {
  name   = "${var.environment}-${var.app}-lambda"
  vpc_id = var.vpc_id

  description = "For access to RDS"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment} ${var.app} Lambda SG"
    CostCenter  = var.app
    Environment = var.environment
  }
}
