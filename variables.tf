provider "vsphere" {
  user           = "Administrator@vsphere.local"
  password       = "4!0XkF!n"
  vsphere_server = "10.134.214.130"
  allow_unverified_ssl = true
}

// The domain name to set up each virtual machine as.
variable "virtual_machine_domain" {
  type = "string"
  default = "coc.net"
}

// IPaddress for fiweb
variable "virtual_machine_fiweb_ip" {
  type = "string"
  default = "10.134.214.137"
}

// IPaddress for fidb
variable "virtual_machine_fidb_ip" {
  type = "string"
  default = "10.134.214.160"
}

// netmask
variable "virtual_machine_netmask" {
  type = "string"
  default = "26"
}

// The default gateway for the network the virtual machines reside in.
variable "virtual_machine_gateway" {
  type = "string"
  default = "10.134.214.137"
}

// The default DNS servers
variable "virtual_machine_dns_servers" {
  type = "list"
  default = ["8.8.8.8"]
}


variable "folder_name" {
  type = "string"
  default = "fi"
  description = "folder name for the vms"
}

variable "fiweb-name" {
  type = "string"
  default = "fiweb"
  description = "virtual machine name for fiweb"
}

variable "fidb-name" {
  type = "string"
  default = "fidb"
  description = "virtual machine name for fidb"
}

variable "network_route1" {
  type = "string"
  default = "10.0.0.0"
  description = "network route 1"
}

variable "network_route2" {
  type = "string"
  default = "0.0.0.0"
  description = "network route 1"
}

variable "network_netmask1" {
  type = "string"
  default = "255.0.0.0"
  description = "network mask 1"
}

variable "network_netmask2" {
  type = "string"
  default = "0.0.0.0"
  description = "network mask 0"
}

variable "network_gateway1" {
  type = "string"
  default = "10.134.214.129"
  description = "network gateway 1"
}

variable "network_gateway2" {
  type = "string"
  default = "10.134.214.137"
  description = "network gateway 1"
}


