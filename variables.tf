variable "az_prefix" {
  type    = string
  description = "Prefix for all resources"
}
variable "prefix"{
  type    = string
  description = "Prefix for container registry"
}
variable "dns_names"{
  type = list
  description = "DNS names for domain"
}
variable "azurelocation" {
  type    = string
  description = "Azure region"
}
variable "managed" {
  type    = string
  description = "True if managed by terraform"
}
variable "level" {
  type    = string
  description = "Environment level"
}
variable "address_space" {
  type = list
  description = "Address space for VNET"
}
variable "subnet_workers" {
  type = list
  description = "Subnet for workers"
}
variable "subnet_vip" {
  type = list
  description = "Subnet for VIP"
}
variable "subnet_appgw" {
  type = list
  description = "Subnet for Application Gateway"
}
variable "subnet_lb" {
  type = list
  description = "Subnet for Load Balancers"
}
variable "certname"{
  type    = string
  description = "Name of Certificate in Key Vault"
  
}