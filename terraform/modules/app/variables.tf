variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable private_key_path {
  description = "Path to the private key used for ssh access"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base-ansible"
}
variable subnet_id {
  description = "Subnets for modules"
}
variable database_url {
  description = "Reddit DB address"
}
variable name {
  description = "Resource name, e.g.: reddit-app"
  default     = "reddit-app"
}
