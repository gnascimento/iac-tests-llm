# Security Groups
resource "aws_security_group" "alb_sg" {
  name   = "alb_sg"
  vpc_id = aws_vpc.main.id

  ingress = [{
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP ingress rule"
    self = false
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
  }]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP egress rule"
    self = false
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
  }]

  depends_on = [aws_vpc.main]
  tags = {
    Name = "alb_sg"
  }

}

resource "aws_security_group" "app_sg" {
  name   = "app_sg"
  vpc_id = aws_vpc.main.id

  ingress = [{
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "HTTP ingress rule"
    self = false
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    cidr_blocks = []
  }]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP egress rule"
    self = false
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
  }]

  tags = {
    Name = "app_sg"
  }
}

# Application Load Balancer (ALB)
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

resource "aws_lb_target_group" "app_tg" {
  name       = "app-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_vpc.main]
  tags = {
    Name = "app_tg"
  }
  # Configuração do Health Check
  health_check {
    enabled             = true
    interval            = 60          # Intervalo entre verificações de saúde em segundos
    timeout             = 5           # Tempo limite para cada verificação de saúde em segundos
    healthy_threshold   = 2           # Número de verificações bem-sucedidas antes de marcar como saudável
    unhealthy_threshold = 2           # Número de falhas consecutivas antes de marcar como não saudável
    matcher             = "200"       # Código de status HTTP esperado para considerar saudável
    path                = "/"         # Caminho que o ALB usará para o health check
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  tags = {
    Name = "app_listener"
  }
}

# S3 Bucket para hospedagem de site estático
resource "aws_s3_bucket" "bucket_for_website" {
  bucket = "gabe-bucket-270392"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket                  = aws_s3_bucket.bucket_for_website.id
  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "static_web_site" {
  bucket = aws_s3_bucket.bucket_for_website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

# Habilitando o versionamento no Bucket
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.bucket_for_website.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Página estática
resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.bucket_for_website.bucket
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html" # Define o tipo MIME
}

resource "aws_s3_bucket_object" "error" {
  bucket       = aws_s3_bucket.bucket_for_website.bucket
  key          = "error.html"
  source       = "error.html"
  content_type = "text/html" # Define o tipo MIME
}

# Launch Template com user_data
resource "aws_launch_template" "app_lt_custom" {
  name   = "app-server-custom"
  image_id      = "ami-0866a3c8686eaeeba" # Ubuntu Server 24.04 LTS (HVM), SSD Volume Type
  instance_type = "t2.micro"

  user_data = base64encode(<<-EOF
              #!/bin/bash
                INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
                REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
                sudo apt update
                sudo apt install -y apache2
                echo "Hello World from $INSTANCE_ID" | sudo tee /var/www/html/index.html
                sudo systemctl start apache2
                sudo systemctl enable apache2
              EOF
  )

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }

  lifecycle {
    create_before_destroy = true
  }

  # Configure instance metadata options
  metadata_options {
    http_endpoint               = "enabled"  # Ensures metadata service is enabled
    http_tokens                 = "optional" # Allows both IMDSv1 and IMDSv2
    http_put_response_hop_limit = 2          # Controls the max hop limit (default is 1)
  }
}

# Auto Scaling Group usando o Launch Template
resource "aws_autoscaling_group" "app_asg_custom" {
  name = "app_asg_custom"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 2
  vpc_zone_identifier = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
  launch_template {
    id      = aws_launch_template.app_lt_custom.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]

  tag {
    key                 = "Name"
    value               = "App Server Custom"
    propagate_at_launch = true
  }
}
