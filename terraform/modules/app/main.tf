resource "yandex_compute_instance" "app" {
  name = "reddit-app-${var.label}"
  labels = {
    tags = "reddit-app-${var.label}"
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
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

  connection {
    type  = "ssh"
    host  = self.network_interface.0.nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.privat_key_path)
  }

  provisioner "file" {
    source      = "${path.module}/puma.service"
    destination = "/tmp/puma.service"
  }

  provisioner "remote-exec" {
    script = "../files/deploy.sh"
  }

  scheduling_policy {
    preemptible = true
  }
  depends_on = [local_file.generate_service]
}

resource "local_file" "generate_service" {
  content = templatefile("${path.module}/puma.tpl", {
    addrs = var.db_url,
  })
  filename = "${path.module}/puma.service"
}
