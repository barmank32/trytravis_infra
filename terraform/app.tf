resource "yandex_compute_instance" "app" {
  name = "reddit-app"
  labels = {
    tags = "reddit-app"
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      # Указать id образа созданного в предыдущем домашнем задании
      image_id = var.app_disk_image
    }
  }

  network_interface {
    # Указан id подсети default-ru-central1-a
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  scheduling_policy {
    preemptible = true
  }

}
