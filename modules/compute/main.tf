locals {
  key_proxy_name   = replace(basename(var.key_proxy), ".pub", "")
  key_general_name = replace(basename(var.key_general), ".pub", "")
}

resource "aws_instance" "svr_proxy" {
  ami                         = var.ami
  instance_type               = "t3.small"
  subnet_id                   = var.subnet_publica_id
  vpc_security_group_ids      = [var.sg_proxy_id]
  key_name                    = local.key_proxy_name
  associate_public_ip_address = true

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 32
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-svr-proxy"
    }
  )
}

resource "aws_eip" "proxy_eip" {
  domain   = "vpc"
  instance = aws_instance.svr_proxy.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-proxy-eip"
    }
  )
}

resource "aws_instance" "svr_back" {
  ami                         = var.ami
  instance_type               = "c7i-flex.large"
  subnet_id                   = var.subnet_privada_id
  vpc_security_group_ids      = [var.sg_back_id]
  key_name                    = local.key_general_name
  associate_public_ip_address = false

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 32
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-svr-back"
    }
  )
}

resource "aws_instance" "svr_ia" {
  ami                         = var.ami
  instance_type               = "m7i-flex.large"
  subnet_id                   = var.subnet_privada_id
  vpc_security_group_ids      = [var.sg_ia_id]
  key_name                    = local.key_general_name
  associate_public_ip_address = false

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 64
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-svr-ia"
    }
  )
}

resource "aws_instance" "svr_front" {
  ami                         = var.ami
  instance_type               = "c7i-flex.large"
  subnet_id                   = var.subnet_privada_id
  vpc_security_group_ids      = [var.sg_front_id]
  key_name                    = local.key_general_name
  associate_public_ip_address = false

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 32
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-svr-front"
    }
  )
}

resource "aws_instance" "svr_db" {
  ami                         = var.ami
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_privada_id
  vpc_security_group_ids      = [var.sg_db_id]
  key_name                    = local.key_general_name
  associate_public_ip_address = false

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    volume_size           = 64
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-svr-db"
    }
  )
}
