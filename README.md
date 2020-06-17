# OpenRMF at AWS

This project provisions an EC2 server with the OpenRMF software running on it.

## Create PKI Public Key

You'll need an EC2 key pair in order to SSH into the server and to let Ansible run its playbooks. After creating a key pair, generate a public key using the following command:

```
ssh-keygen -y -f $HOME/Downloads/pem/openrmf.pem > $HOME/Downloads/pem/openrmf.pub
```

## Initialization

* Setup `variables.tf`. Make sure to update these variables:
    * pki_private_key
    * aws_profile
    * subnet_id
    * vpc_id

* Terraform

```bash
terraform init
terraform apply
```

* Ansible

```bash
./run-playbook.sh
```
