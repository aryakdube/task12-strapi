provider "aws" {
  region = "us-east-2"
}

# Use default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "aryak-strapi-cluster"
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "aryak-strapi-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  network_mode             = "awsvpc"
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/aryak-strapi-app:latest"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
          protocol      = "tcp"
        }
      ],
      essential = true,
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
        name  = "DATABASE_URL"
        value = "postgresql://${var.db_username}:${var.db_password}@aryak-strapi-postgres.cbymg2mgkcu2.us-east-2.rds.amazonaws.com:5432/${var.db_name}"
        },
        {
          name  = "APP_KEYS"
          value = "H5mnz8odDwNsrPrHYZMK+w==,vflz6dcxdZtLmb/qr/38bg==,2RQzSRADDruCIWu1qHtkGw==,gwSyUiod2cNkoIifB1wClw=="
        },
        {
          name  = "JWT_SECRET"
          value = "EYw8dnO6uAJgieoP0V2QCA=="
        },
        {
          name  = "API_TOKEN_SALT"
          value = "ntITJUKq7KPLSs3yMDWmWw=="
        },
        {
          name  = "ADMIN_JWT_SECRET"
          value = "EYw8dnO6uAJgieoP0V2QCA=="
        },
        {
          name  = "TRANSFER_TOKEN_SALT"
          value = "6hJTsNusRF6kArOCiUI0aA=="
        },
        {
          name  = "ENCRYPTION_KEY"
          value = "oQQVoC1EbAsvD0UUeGNHDA=="
        },
        
      ]
      logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.strapi_logs.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs/strapi"
  }
}

    }
  ])
}

# Security group for ALB and ECS tasks
resource "aws_security_group" "ecs_sg" {
  name        = "aryak-strapi-ecs-sg12"
  description = "Allow HTTP from anywhere and Postgres traffic within SG"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Postgres access"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow container port"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  
}

# Load Balancer
resource "aws_lb" "alb" {
  name               = "aryak-strapi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets = [
  "subnet-024126fd1eb33ec08", 
  "subnet-03e27b60efa8df9f0"  
]
}


resource "aws_lb_target_group" "tg_blue" {
  name        = "aryak-strapi-blue-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "tg_green" {
  name        = "aryak-strapi-green-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}


# Listener to forward HTTP to target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

 default_action {
  type             = "forward"
  target_group_arn = aws_lb_target_group.tg_blue.arn
}
}


## ECS Service
resource "aws_ecs_service" "strapi_service" {
  name            = "aryak-strapi-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  desired_count   = 1
  capacity_provider_strategy {
  capacity_provider = "FARGATE_SPOT"
  weight            = 1
}

  network_configuration {
    subnets = [
  "subnet-024126fd1eb33ec08", 
  "subnet-03e27b60efa8df9f0"  
]

    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
   deployment_controller {
    type = "CODE_DEPLOY"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg_blue.arn 
    container_name   = "strapi"
    container_port   = 1337
  }
}

resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi-aryak"      
  retention_in_days = 14                
  tags = {
    "Name" = "StrapiLogs"
  }
}
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "aryak-strapi-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU usage > 80% for Strapi ECS Service"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
}
resource "aws_cloudwatch_metric_alarm" "low_task_count" {
  alarm_name          = "aryak-strapi-task-count-low"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  statistic           = "Minimum"
  period              = 60
  threshold           = 1
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
}
resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "aryak-strapi-ecs-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 6,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.strapi_service.name, "ClusterName", aws_ecs_cluster.strapi_cluster.name ],
            [ ".", "MemoryUtilization", ".", ".", ".", "." ]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Strapi ECS Utilization"
        }
      }
    ]
  })
}
resource "aws_iam_role" "codedeploy_role" {
  name = "aryak-ecs-codedeploy-role"  

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_attach" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}


resource "aws_codedeploy_app" "ecs_codedeploy" {
  name = "aryak-strapi-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "ecs_codedeploy_group" {
  app_name               = aws_codedeploy_app.ecs_codedeploy.name
  deployment_group_name  = "aryak-strapi-dg"
  service_role_arn       = aws_iam_role.codedeploy_role.arn

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster.name
    service_name = aws_ecs_service.strapi_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.listener.arn]
      }
      target_group {
        name = aws_lb_target_group.tg_blue.name
      }
      target_group {
        name = aws_lb_target_group.tg_green.name
      }
    }
  }

  depends_on = [aws_ecs_service.strapi_service]
}
resource "aws_iam_role_policy" "ecs_codedeploy_inline_policy" {
  name = "AllowECSDescribe"
  role = aws_iam_role.codedeploy_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeClusters",
          "elasticloadbalancing:*",
          "autoscaling:*",
          "cloudwatch:*"
        ],
        Resource = "*"
      }
    ]
  })
}
