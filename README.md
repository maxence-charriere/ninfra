# ninfra

A terraform module that creates:

- A load balancer
- An auto scalling group
- 5 ububtu VM with Apache that serve "hello world"

## Install

- Run those commands:

    ```sh
    # Tools
    brew install terraform
    brew install packer

    # Build Ububtu with Apache
    packer build apache-packer.json
    ```

- [Create a KeyPair](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:sort=keyName) and save it on disk.

- Change `image_id` and `key_name` in `main.tf`

    ```tf
    module "ninfra" {
    source = "./infra"

    # Use the image_id created with:
    # packer build apache-packer.json
    image_id = "ami-081c4a2dcf94faaa0"


    # Use the key-pair created in:
    # https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#KeyPairs:sort=keyName
    key_name = "ssh-key"
    }
    ```

- Build the infra

    ```sh
    terraform init
    terraform apply
    ```

## Test autoscalling

### Remove instance by hand

- Go to [EC2 instance dashboard](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:sort=instanceState)
- Terminate a `ninfra instance` the 

### Make a instance unhealthy

- Find an instance ip on  the [EC2 instance dashboard](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:sort=instanceState)
- Go to a terminal and ssh to that instance

    ```sh
    # Change acl of the key downloaded when keyPair was created.
    chmod 0600 ssh-key.pem.txt

    # Ssh to the instance.
    ssh -i ssh-key.pem.txt ubuntu@INSTANCE_IP

    # Kill apache.
    sudo killall -9 apache2
    ```

### Monitoring

- [EC2 instance dashboard](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Instances:sort=instanceState)
- [Target group dashboard](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#TargetGroups:sort=targetGroupName) on the Targets tab.
- [Auto Scalling dashboard](https://us-west-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-west-2#AutoScalingGroups:id=ninfra;view=history)
  - Activity History tab
  - Instances Tab
- [Load Balancers dashboard](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#LoadBalancers:sort=loadBalancerName) - Enter the DNS Name in a browser to see Hello World

## Uninstall

- [Deregister](https://us-west-2.console.aws.amazon.com/ec2/v2/home?region=us-west-2#Images:visibility=owned-by-me;sort=name) `ami-ninfra`
- Destroy the infra

    ```
    terraform destroy
    ```
