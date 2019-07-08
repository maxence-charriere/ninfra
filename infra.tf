provider "aws" {
  profile = "default"
  region  = "us-west-2"
}


resource "aws_vpc" "ninfra" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "ninfra"
  }
}

resource "aws_route" "ninfra_route" {
  route_table_id         = "${aws_vpc.ninfra.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ninfra_igw.id}"
}

resource "aws_internet_gateway" "ninfra_igw" {
  vpc_id = "${aws_vpc.ninfra.id}"
}

resource "aws_security_group" "ninfra_sg_lb" {
  name        = "ninfra-sg-lb"
  description = "Allow http traffic for load balancer"
  vpc_id      = "${aws_vpc.ninfra.id}"

  # http
  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_security_group" "ninfra_sg_instances" {
  name        = "ninfra-sg-instances"
  description = "Allow http traffic and ssh for instances"
  vpc_id      = "${aws_vpc.ninfra.id}"

  # http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # ssh
  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_subnet" "ninfra_subnet_a" {
  vpc_id                  = "${aws_vpc.ninfra.id}"
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "ninfra_subnet_b" {
  vpc_id                  = "${aws_vpc.ninfra.id}"
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true
}

resource "aws_lb" "ninfra_lb" {
  name               = "ninfra"
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.ninfra_sg_lb.id}"]

  subnets = [
    "${aws_subnet.ninfra_subnet_a.id}",
    "${aws_subnet.ninfra_subnet_b.id}",
  ]
}

resource "aws_lb_target_group" "ninfra_lb_target_group" {
  name                 = "ninfra"
  target_type          = "instance"
  protocol             = "HTTP"
  port                 = 80
  vpc_id               = "${aws_vpc.ninfra.id}"
  deregistration_delay = 15

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/index.html"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200,204"
  }
}

resource "aws_lb_listener" "ninfra_lb_listener" {
  load_balancer_arn = "${aws_lb.ninfra_lb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ninfra_lb_target_group.arn}"
  }
}

resource "aws_autoscaling_group" "ninfra_autoscaling_group" {
  name             = "ninfra"
  max_size         = 5
  desired_capacity = 5
  min_size         = 1

  health_check_type         = "ELB"
  health_check_grace_period = 60
  default_cooldown          = 15

  target_group_arns = ["${aws_lb_target_group.ninfra_lb_target_group.arn}"]

  vpc_zone_identifier = [
    "${aws_subnet.ninfra_subnet_a.id}",
    "${aws_subnet.ninfra_subnet_b.id}",
  ]

  launch_template {
    id      = "${aws_launch_template.ninfra_launch_template.id}"
    version = "$Latest"
  }
}

resource "aws_launch_template" "ninfra_launch_template" {
  name_prefix            = "ninfra"
  image_id               = "ami-081c4a2dcf94faaa0"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.ninfra_sg_instances.id}"]

  key_name = "ssh"

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ninfra"
    }
  }
}
