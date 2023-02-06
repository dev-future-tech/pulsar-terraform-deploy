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
