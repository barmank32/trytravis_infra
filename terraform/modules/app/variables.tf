variable public_key_path {
  description = "Path to the public key used for ssh access"
}
variable privat_key_path {
  description = "Path to the public key used for ssh access"
}
variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}
variable subnet_id {
  description = "Subnets for modules"
}
variable label {
  description = "Label for modules"
}
variable db_url {
  description = "env DATABASE_URL"
}
