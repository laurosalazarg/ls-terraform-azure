variable "az_prefix" {
  type    = string
  default = "dv_aztf_slzrcloud_"
}
variable "prefix"{
  default = "dv0aztf0slzr0cloud0"
}
variable "dns_names"{
  default = ["slzr.cloud", "*.slzr.cloud"]
}
variable "azurelocation" {
  type    = string
  default = "eastus"
}
variable "managed" {
  type    = string
  default = "true"
}
variable "level" {
  type    = string
  default = "dev"
}
variable "address_space" {
  default = ["10.20.0.0/16"]
}
variable "subnet_workers" {
  default = ["10.20.0.0/24"]
}
variable "subnet_vip" {
  default = ["10.20.1.0/24"]
}
variable "subnet_appgw" {
  default = ["10.20.2.0/24"]
}
variable "subnet_lb" {
  default = ["10.20.3.0/24"]
}
variable "certname"{
  default = "self-imported-cert-03"
}