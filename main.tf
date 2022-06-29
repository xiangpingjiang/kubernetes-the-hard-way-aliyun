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

# Create a new ECS instance for a VPC
resource "alicloud_security_group" "group" {
  name        = "tf_test_foo"
  description = "foo"
  vpc_id      = alicloud_vpc.vpc.id
}
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
  cidr_ip           = "172.16.0.0/16"
}
data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

# Create a new ECS instance for VPC
resource "alicloud_vpc" "vpc" {
  vpc_name       = var.name
  cidr_block     = "172.16.0.0/16"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/24"
  zone_id           = data.alicloud_zones.default.zones[0].id
  vswitch_name      = var.name
}
resource "alicloud_ecs_key_pair" "publickey" {
  key_pair_name = "my_public_key"
  public_key    = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDcnZJPmDEMc/k24x+ChwgS3hklsyxTQF8THmhRnSNfbqQdbkQW01Qf83r9D4zMCpDaMXFYFE2DkmpK5EN2H5w4p5XtqdHH44FoaT46C33qE7bEUaWTOyXbwUQbxsDZ4d5RJfHc7b9pLJTrmQi9GyA/MFwgL0WPsjCuI066ZPyNtXvfMub36dvbBQ1a9BA62DyHrBRvrbpvUGGKxHYm1csPFbe9+gbhOuKcqBSNs/rF06cYsn52gCuljgkV9uQhhBghw0uL38V1EGctGNOXi1NPLyenPXcdhxxthJC5xdpwVRbnNRu+Y+ZtJCZexnRsTIwC7bjgKt3rwEOJEK8l162ZuEEwcABK6ovPW8WqVZZJzHLyVZ8j+HgWiFvH+BFErQRplTPOu+bBHLnc+XhhPwzbV/kdzkoWhWF0iQir5IBMYc1xrQSWc/4MSrnGIRn7OiF8txe0BLrijxYq8RS6Isz6R2i+xLk5QLa3LQR9xiXBQQZwxVNbWrOkFQbxgn/yN20= xpj@xpj-20j6a012cd"
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




# resource "alicloud_instance" "instance" {
#   # cn-beijing
#   # availability_zone = "cn-qingdao-b"
#   security_groups   = alicloud_security_group.group.*.id
#   internet_charge_type = "PayByTraffic"
#   instance_charge_type = "PostPaid"
#   spot_strategy        = "SpotWithPriceLimit"
#   spot_price_limit     = "0.15"
#   key_name             = "my_public_key"

#   # series III
#   instance_type              = "ecs.t5-lc2m1.nano"
#   system_disk_category       = "cloud_efficiency"
#   system_disk_name           = "test_foo_system_disk_name"
#   system_disk_description    = "test_foo_system_disk_description"
#   image_id                   = data.alicloud_images.default.images.0.id
#   instance_name              = "test_foo"
#   vswitch_id                 = alicloud_vswitch.vswitch.id
#   internet_max_bandwidth_out = 10
#   data_disks {
#     name        = "disk2"
#     size        = 20
#     category    = "cloud_efficiency"
#     description = "disk2"
#     encrypted   = true
#   }
# }

data "alicloud_instances" "instances_ds" {
  status     = "Running"
}
output "instances" {
  value =  [for instance in data.alicloud_instances.instances_ds.instances :
  "${instance.public_ip},${instance.private_ip}"]
}