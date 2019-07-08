provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

module "ninfra" {
  source = "./infra"

  # Use the image_id created with:
  # packer build apache-packer.json
  # https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Images:visibility=owned-by-me;sort=name
  image_id = "ami-00d81eb1bbd0626bb"


  # Use the key-pair created in:
  # https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:sort=keyName
  key_name = "ssh-key"
}
