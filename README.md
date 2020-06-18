# OpenRMF at AWS

This project provisions an EC2 server with the OpenRMF software running on it.

See **Caution** section below.

2020-Jun-18 - The project is based on OpenRMF Core OSS 1.0.

## Links

* https://www.openrmf.io/

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

* SSH to the EC2 server.

```bash
./ssh-to-server.sh
```

* Visit the Keycloak web page.

```bash
./open-keycloak-page.sh
```

* Visit the OpenRMF web page.

```bash
./open-openrmf-page.sh
```

## Caution

In order to make this automation work, I needed to provide my own versions of two files. These are `setup-realm-linux.sh` and `docker-compose.yml` from the OpenRMF zip file. This makes this project brittle.

