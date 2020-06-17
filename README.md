# OpenRMF at AWS

This project provisions an EC2 server with the OpenRMF software running on it.

## Create PKI Public Key

You'll need an EC2 key pair in order to SSH into the server and to let Ansible run its playbooks. After creating a key pair, generate a public key using the following command:

```
ssh-keygen -y -f $HOME/Downloads/pem/openrmf.pem > $HOME/Downloads/pem/openrmf.pub
```

## Initialization

* Copy the variable example file.

```bash
cp variables.tf.example variables.tf
```

* Setup `variables.tf`. Make sure to update these variables:
    * aws_profile
    * pki_private_key
    * rmf_admin_password
    * subnet_id
    * vpc_id

* Terraform

```bash
terraform init
terraform apply
```

* Visit the Keycloak web page.

```bash
./open-keycloak-page.sh
```
