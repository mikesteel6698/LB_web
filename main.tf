terraform {
  backend "s3" {
    bucket         = "tfbackendpro"
    key            = "terraform-state/terraform.tfstate"
    region         = "us-east-1"
    # dynamodb_table = "lock_table"
    # encrypt        = true
  }
}

module "testvpc_module" {
  source            = "../modules/vpc_module"
  vpc_cidr          = var.test_vpc_cidr
  availability_zone = var.test_az[*]
}

module "testsg_module" {
  source = "../modules/sg_module"
  vpc_id = module.testvpc_module.vpc_id
}

resource "aws_instance" "pro_1" {
  ami               = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.test_az[0]
  key_name          = var.key
  root_block_device {
    volume_size = var.root_volume_size
  }
  subnet_id                   = module.testvpc_module.subnet_id[0]
  vpc_security_group_ids      = [module.testsg_module.sg_id]
  associate_public_ip_address = true
  tags = {
    name = "ansible"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo echo 'ubuntu ALL=(ALL:ALL) ALL' >> /etc/sudoers",
      "sudo apt update -y",
      "sudo apt install curl -y",
      "sudo apt install -y software-properties-common",
      "sudo add-apt-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "sudo apt install python3 -y",
      "sudo apt install python3-pip -y",
      "sudo pip3 install boto3",
      "sudo apt install unzip",
      "mkdir ${var.home_directory}/.aws",
      "mkdir ${var.home_directory}/ansible",
    ]
  }

  provisioner "file" {
    source      = "../ansible"
    destination = var.home_directory
  }

  provisioner "file" {
    source      = "../new.pem"
    destination = "${var.home_directory}/.ssh/new.pem"
  }

  provisioner "file" {
    source      = "../config"
    destination = "${var.home_directory}/.aws/config"
  }

  provisioner "file" {
    source      = "../credentials"
    destination = "${var.home_directory}/.aws/credentials"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo unzip ${var.home_directory}/ansible/awscli-exe-linux-x86_64.zip -d ${var.home_directory}/ansible/",
      "sudo ${var.home_directory}/ansible/aws/install",
      "cd ${var.home_directory}/ansible/inventory/",
      "chmod 600 ${var.home_directory}/.ssh/new.pem",
      "ansible-playbook newpb.yaml"
    ]

  }
  connection {
    type        = "ssh"
    user        = var.username
    private_key = file("../new.pem")
    host        = self.public_ip
  }
}

resource "aws_instance" "pro_2" {
  count             = length(module.testvpc_module.subnet_id)
  ami               = var.ami_id
  instance_type     = var.instance_type
  availability_zone = var.test_az[count.index]
  key_name          = var.key
  root_block_device {
    volume_size = var.root_volume_size
  }
  subnet_id                   = module.testvpc_module.subnet_id[count.index]
  vpc_security_group_ids      = [module.testsg_module.sg_id]
  associate_public_ip_address = true

  tags = {
    host = var.nodes_tags[count.index]
    name = var.username
  }
}

resource "aws_lb" "pro_alb" {
  name               = "testalb123"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.testsg_module.sg_id]
  subnets            = module.testvpc_module.subnet_id[*]
}

resource "aws_lb_target_group" "pro_tg" {
  name        = "testtg123"
  target_type = "instance"
  protocol    = "HTTP"
  port        = 80
  vpc_id      = module.testvpc_module.vpc_id
}

resource "aws_lb_target_group_attachment" "pro_tga1" {
  target_group_arn = aws_lb_target_group.pro_tg.arn
  target_id        = aws_instance.pro_2[0].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "pro_tga2" {
  target_group_arn = aws_lb_target_group.pro_tg.arn
  target_id        = aws_instance.pro_2[1].id
  port             = 80
}

resource "aws_lb_listener" "pro_listener" {
  load_balancer_arn = aws_lb.pro_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pro_tg.id
  }
}
resource "aws_route53_zone" "pro_zone" {
  name = "testweb1.tk"
}

resource "aws_route53_record" "pro_record" {
  name    = "www.testweb1.tk"
  ttl     = 300
  type    = "CNAME"
  zone_id = aws_route53_zone.pro_zone.id
  records = [aws_lb.pro_alb.dns_name]
}

