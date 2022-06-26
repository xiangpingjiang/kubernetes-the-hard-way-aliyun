terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = "1.172.0"
    }
  }
}
provider "alicloud" {
  region     = "cn-qingdao"
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

resource "alicloud_kms_key" "key" {
  description            = "Hello KMS"
  pending_window_in_days = "7"
  status                 = "Enabled"
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

resource "alicloud_slb_load_balancer" "slb" {
  load_balancer_name       = "test-slb-tf"
  vswitch_id = alicloud_vswitch.vswitch.id
}

resource "alicloud_instance" "instance" {
  # cn-beijing
  availability_zone = "cn-qingdao-b"
  security_groups   = alicloud_security_group.group.*.id
  internet_charge_type = "PayByTraffic"
  instance_charge_type = "PostPaid"
  spot_strategy        = "SpotWithPriceLimit"
  spot_price_limit     = "0.15"

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
    name        = "disk2"
    size        = 20
    category    = "cloud_efficiency"
    description = "disk2"
    encrypted   = true
    kms_key_id  = alicloud_kms_key.key.id
  }
}