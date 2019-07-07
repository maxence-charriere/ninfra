provider "aws" {
  profile = "default"
  region  = "us-west-2"
}


resource "aws_vpc" "ninfra" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "ninfra_igw" {
  vpc_id = "${aws_vpc.ninfra.id}"
}

resource "aws_subnet" "ninfra_subnet_a" {
  vpc_id            = "${aws_vpc.ninfra.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "ninfra_subnet_b" {
  vpc_id            = "${aws_vpc.ninfra.id}"
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}

resource "aws_lb" "ninfra_lb" {
  name               = "ninfra"
  load_balancer_type = "application"

  subnets = [
    "${aws_subnet.ninfra_subnet_a.id}",
    "${aws_subnet.ninfra_subnet_b.id}",
  ]
}

resource "aws_lb_target_group" "ninfra_lb_target_group" {
  name        = "ninfra"
  target_type = "instance"
  protocol    = "HTTP"
  port        = 80
  vpc_id      = "${aws_vpc.ninfra.id}"

  health_check {
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/health"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200,204"
  }
}

resource "aws_lb_listener" "ninfra_lb_listener" {
  load_balancer_arn = "${aws_lb.ninfra_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.ninfra_lb_target_group.arn}"
  }
}

resource "aws_autoscaling_group" "ninfra_autoscaling_group" {
  name             = "ninfra"
  max_size         = 0
  desired_capacity = 0
  min_size         = 0

  health_check_type         = "ELB"
  health_check_grace_period = 60
  default_cooldown          = 5

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
  name_prefix   = "ninfra"
  image_id      = "ami-a0cfeed8"
  instance_type = "t2.micro"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ninfra"
    }
  }
}

