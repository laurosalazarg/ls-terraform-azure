variable "az_prefix" {
  type        = string
  description = "Prefix for all resources"
}
variable "prefix" {
  type        = string
  description = "Prefix for container registry"
}
variable "prefix_k8s" {
  type        = string
  description = "Prefix for K8"
}
variable "dns_names" {
  type        = list(any)
  description = "DNS names for domain"
}
variable "azurelocation" {
  type        = string
  description = "Azure region"
}
variable "managed" {
  type        = string
  description = "True if managed by terraform"
}
variable "level" {
  type        = string
  description = "Environment level"
}
variable "address_space" {
  type        = list(any)
  description = "Address space for VNET"
}
variable "subnet_workers" {
  type        = list(any)
  description = "Subnet for workers"
}
variable "subnet_vip" {
  type        = list(any)
  description = "Subnet for VIP"
}
variable "subnet_appgw" {
  type        = list(any)
  description = "Subnet for Application Gateway"
}
variable "subnet_lb" {
  type        = list(any)
  description = "Subnet for Load Balancers"
}
variable "auth_ip" {
  type        = list(any)
  description = "Allowed IPs to manage cluster"
}
variable "certname" {
  type        = string
  description = "Name of Certificate in Key Vault"

}
variable "public_ssh_key" {
  description = "An ssh key set in the main variables of the terraform-azurerm-aks module"
  default     = ""
}
variable "private_ssh_key" {
  description = "An ssh key set in the main variables of the terraform-azurerm-aks module"
  default     = ""
}

