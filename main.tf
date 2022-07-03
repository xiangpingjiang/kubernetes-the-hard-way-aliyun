terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.173.0"
    }
  }
}
provider "alicloud" {
}


data "alicloud_images" "default" {
  name_regex  = "^ubuntu"
  most_recent = true
  owners      = "system"
}


variable "name" {
  default = "auto_provisioning_group"
}

# Create a new VPC
resource "alicloud_vpc" "vpc" {
  vpc_name       = var.name
  cidr_block     = "10.240.0.0/24"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "10.240.0.0/24"
  zone_id           = "cn-beijing-a"
  vswitch_name      = var.name
}

resource "alicloud_slb_load_balancer" "slb" {
  load_balancer_name       = "test-slb-tf"
  vswitch_id = alicloud_vswitch.vswitch.id
  address_type       = "intranet"
  load_balancer_spec = "slb.s2.small"
}


resource "alicloud_security_group" "group" {
  name        = "tf_test_foo"
  description = "foo"
  vpc_id      = alicloud_vpc.vpc.id
}

# Create 3 firewall rules that allows external SSH, ICMP, and HTTPS:
resource "alicloud_security_group_rule" "tcp_22" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "tcp_6443" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "6443/6443"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "0.0.0.0/0"
}
# Create a firewall rule that allows internal communication across all protocols:

resource "alicloud_security_group_rule" "internal" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "10.240.0.0/24"
}

resource "alicloud_security_group_rule" "cidr_range" {
  type              = "ingress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  priority          = 1
  security_group_id = alicloud_security_group.group.id
  cidr_ip           = "10.200.0.0/16"
}




resource "alicloud_ecs_key_pair" "publickey" {
  key_pair_name = "my_public_key"
  public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCYEjir/SvY5LnfQrjOe6AKUVdKmSJrx9e2VoapqNoAwJt2qTH85TVBMgpyZ3tvVZF3LM2ITY/+uuNbiLDut0VXIMciOTc5ONR0ek7GMJhydVQIbWvYW8cm6hoSYH+Mg6ugfy/HzziTJYXTDUTsGc/yowbPxpt/XLiSvmW8EqC3rxYCGGoC/34ili3jHg9UX4xXDCRWcPO8HWi+Ks+Nl1Pg319YOXGfoZM+pS10qcxvDDYGhvgP1ib/jVdViytKR75P5hz3nRUtcdOhvby3pWktkNwUBIOV+siml59atxz47k6nEc7XEVvwRbhVU6yOuWouj3tyssBNQKrux2cJAAE3qc6Y3ML9hZ8S/yOmW1DixlQYjQXe5G8SkHumkg0k/HL61G6QMxcBOGCaLGXDr0OZSqblxc1kUe56jHRceKhXJV7GV6Yy+I0FRFjPFPs7SffEBSjgxltZ0NH22rdInyY8duFNLwYLedv/00LSTWSLAxFIcvMiKUv0Wd2/rNHDFqU= xpj@xpj-manjaro"
}




resource "alicloud_ecs_instance_set" "instance_set" {
  amount                        = 5
  security_group_ids   = alicloud_security_group.group.*.id
  internet_charge_type = "PayByTraffic"
  instance_charge_type = "PostPaid"
  spot_strategy        = "SpotWithPriceLimit"
  spot_price_limit     = "0.15"
  key_pair_name             = "my_public_key"


  # series III
  instance_type              = "ecs.t5-lc2m1.nano"
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "test_foo_system_disk_name"
  system_disk_description    = "test_foo_system_disk_description"
  image_id                   = data.alicloud_images.default.images.0.id
  instance_name              = "test_foo"
  vswitch_id                 = alicloud_vswitch.vswitch.id
  internet_max_bandwidth_out = 10
  data_disks {
    disk_name        = "disk2"
    disk_size        = 20
    disk_category    = "cloud_efficiency"
    disk_description = "disk2"
    encrypted   = true
  }
}

data "alicloud_instances" "instances_ds" {
  status     = "Running"
  # name_regex = "test_foo"
}
output "instances" {
  value =  [for instance in data.alicloud_instances.instances_ds.instances :
  "${instance.public_ip},${instance.private_ip}"]
}