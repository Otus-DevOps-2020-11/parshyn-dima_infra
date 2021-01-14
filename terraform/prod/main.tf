provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

locals {
  app_name = "reddit-app-${var.environment}"
  db_name  = "reddit-db-${var.environment}"
}

module "db" {
  source           = "../modules/db"
  name             = local.db_name
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  db_disk_image    = var.db_disk_image
  subnet_id        = var.subnet_id
}

module "app" {
  source           = "../modules/app"
  name             = local.app_name
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  app_disk_image   = var.app_disk_image
  subnet_id        = var.subnet_id
  database_url     = "${module.db.external_ip_address_db}"
}
