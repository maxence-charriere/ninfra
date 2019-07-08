provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

module "ninfra" {
  source = "./infra"

  # Use the image_id created with:
  # packer build apache-packer.json
  image_id = "ami-081c4a2dcf94faaa0"


  # Use the key-pair created in:
  # https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:sort=keyName
  key_name = "ssh-key"
}
