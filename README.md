# Setting up your Cluster

## Prerequisites

* [Terraform](https://www.terraform.io)
* [Terraform Inventory](https://github.com/adammck/terraform-inventory)
* [Ansible](https://www.ansible.com/resources/get-started)


### Install terraform

```
$ brew install terraform
```

### Install Terraform Inventory

```
$ brew install terraform-inventory
```

### Install Ansible

```
$ brew install ansible
```

## Configure your build

The current Terraform scripts, by default, deploy to `us-east-2`, however, this can be configured in the `pulsar.tfvars` file:

```hcl
public_key_path     = "~/.ssh/pulsar_aws.pub"
region              = "us-east-2"
availability_zone   = "us-east-2a"

num_bookie_nodes    = 3
num_zookeeper_nodes = 3
num_broker_nodes    = 2
num_proxy_nodes     = 1

instance_types      = {
  "zookeeper"   = "t3.small"
  "bookie"      = "i3.4xlarge"
  "broker"      = "c5.2xlarge"
  "proxy"       = "c5.2xlarge"
}

base_cidr_block     = "10.0.0.0/16"
```

The main configuration options are:

| Property | Description |
| -------- | ----------- |
| **public_key_path**   | Best practice is to set up an ssh key and set it's local location here. The key will be uploaded and used for ssh access to all machines. |
| **region**            | The region you want to deploy the cluster to. AMIs are looked up based on the AMI name `amzn2-ami-kernel-5.10-hvm-2.0.20230119.1-x86_64-gp2` |
| **availability_zone** | Current all nodes are provisioned to a single AZ                    |
| **num_bookie_nodes**  | The number of nodes to provision that will act as Book Keeper Nodes |
| **num_broker_nodes**  | The number of nodes to provision that will act as Pulsar Brokers    |
| **num_proxy_nodes**   | The number of nodes to provision that will act as Pulsar Proxies    |
| **instance_types**    | Here you can configured the instance types for each type of node    |
| **base_cidr_block**   | The base CIDR block to map the main VPC to                          |

There are 3 steps to provisioning:
* Provisioning the base infrastructure
  * The base infrastructure without any running code is provisioned using Terraform
* Setting up Bookie disk mappings
  * The bookies need to have disks mounted and formatted for optimal performance
* Installing the software
  * For the ZooKeeper servers, a fresh archive of ZooKeeper 3.8.1 is downloaded to the ZooKeeper servers and provisioned as a `systemd` service
  * For the Book Keeper and Pulsar servers, a cope of Apache Pulsar 2.11.0 is downloaded and services set up for: `proxy`, `brokers` and  `bookies`

## Provisioning the base infrastructure

Using Terraform run the `terraform plan -var-file pulsar.tfvars -out pulsar-stack` to review the deployment:

```bash
$ terraform plan -var-file pulsar.tfvars -out pulsar-stack
```

Once the plan succeeds you can then apply the stack:

```bash
$ terraform apply pulsar-stack
```

## Setting up Bookie disk mappings

Next we will set up folder mappings and format them for the BookKeeper nodes:

```bash
$ ansible-playbook --user='ec2-user' --inventory=`which terraform-inventory` setup-disk.yaml
...
PLAY RECAP *******************************************************************************************************
XX.XXX.XX.XX               : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
Y.YYY.YY.YYY               : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
ZZ.ZZ.ZZZ.ZZZ              : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

This will mount and format the following drives: `/mnt/journal` and `/mnt/storage`

## Installing the software

Next we need to download Apache Zoo Keeper and Apache Pulsar and install them on the correct machines.

The deploy-pulsar ansible playbook ensures applications are installed at either `/opt/pulsar` or `/opt/zookeeper`. The Zoo Keeper servers are then configured to the Pulsar Brokers through initialization of the cluster metadata.

This install also installs the Kafka connector by default. If more connectors are required, simply uncomment them in the `deploy-pulsar.yaml` file for them to be installed.

Run the install script:

```bash
$ ansible-playbook --user='ec2-user' --inventory=`which terraform-inventory` --private-key=~/.ssh/pulsar_aws ../deploy-pulsar.yaml
...
PLAY RECAP ***************************************************************************************************************************
AA.AAA.AA.AAA              : ok=13   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
BB.BBB.BB.BB               : ok=12   changed=8    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
CC.CCC.CC.CCC              : ok=12   changed=8    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
DD.DDD.DD.DD               : ok=14   changed=10   unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
E.EEE.EEE.EE               : ok=13   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
F.FFF.FF.FF                : ok=15   changed=11   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
G.GGG.G.GG                 : ok=13   changed=8    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
H.HHH.HH.HHH               : ok=12   changed=8    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
II.II.III.III              : ok=12   changed=8    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0   
localhost                  : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0 
```

Using your ssh key, you should now be able to ssh to any of the nodes:

```bash
$ ssh -i ~/.ssh/pulsar_aws ec2-user@F.FFF.FF.FF

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
9 package(s) needed for security, out of 9 available
Run "sudo yum update" to apply all updates.
$
```

# Testing your cluster

Making sure you have a local copy of Apache Pulsar, we want to configure the `$PULSAR_HOME/conf/client.conf` file:

Using the outputs from terraform (`terraform outputs`) update the following configuration values:

```
webServiceUrl=(value from pulsar_web_url)
brokerServiceUrl=(value from pulsar_service_url)
```

Then test the conections with a quick query of the clusters:

```bash
$ bin/pulsar-admin clusters list
local
$
```

Let's check to see what tenants and namespaces exist:

```bash
$ bin/pulsar-admin tenants list
public
pulsar
$ bin/pulsar-admin tenants get public
{
  "adminRoles" : [ ],
  "allowedClusters" : [ "local" ]
}
$ bin/pulsar-admin namespaces list public
public/default
$ bin/pulsar-admin topics create public/default/alerts
$ bin/pulsar-admin topics list public/default         
persistent://public/default/alerts
```

Now that we have created the topic `alerts`, let's send some messages to it!

In one terminal window, create a new subcriber:

```bash
$ bin/pulsar-client consume persistent://public/default/alerts -n 100 -s "pulsar-consumer" 
[persistent://public/default/alerts][pulsar-consumer] Subscribed to topic on pulsar-elb-<HOST>/<IP Address>:6650 -- consumer: 0
```

In another terminal window, run the following to create some messages:

```bash
$ bin/pulsar-client produce persistent://public/default/alerts --messages "$(seq -s, -f 'Message NO.%g' 1 10)"
...
PulsarClientTool - 10 messages successfully produced
```

You should see your messages arrive in your consumer:

```bash
----- got message -----
key:[null], properties:[], content:Message NO.1
----- got message -----
key:[null], properties:[], content:Message NO.2
----- got message -----
key:[null], properties:[], content:Message NO.3
----- got message -----
key:[null], properties:[], content:Message NO.4
----- got message -----
key:[null], properties:[], content:Message NO.5
----- got message -----
key:[null], properties:[], content:Message NO.6
----- got message -----
key:[null], properties:[], content:Message NO.7
----- got message -----
key:[null], properties:[], content:Message NO.8
----- got message -----
key:[null], properties:[], content:Message NO.9
----- got message -----
key:[null], properties:[], content:Message NO.10
```

