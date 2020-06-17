# When a profile is specified, tf will try to use 
# ~/.aws/credentials.

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

resource "aws_key_pair" "openrmf" {
  public_key = file(var.pki_public_key)
}

resource "aws_instance" "openrmf" {
  ami           = var.ami
  associate_public_ip_address = "true"
  instance_type = var.instance_type
  key_name      = aws_key_pair.openrmf.key_name
  subnet_id     = var.subnet_id
  vpc_security_group_ids = [ 
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_any_outbound.id,
    aws_security_group.allow_keycloak.id,
    aws_security_group.allow_openrmf.id
  ]

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.pki_private_key)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y python3"
    ]  
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ${var.ssh_user} -i '${self.public_ip},' --private-key ${var.pki_private_key} playbook.openrmf.yml" 
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  tags = {
    Name = "openrmf"
  }
}

resource "local_file" "inventory" {
  content = "[all]\n${aws_instance.openrmf.public_ip}"
  filename = "${path.module}/inventory"
}
