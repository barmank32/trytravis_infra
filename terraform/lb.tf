resource "yandex_lb_target_group" "app_group" {
  name = "app-target-group"

  dynamic "target" {
    for_each = [for s in yandex_compute_instance.app : {
      address = s.network_interface.0.ip_address
      subnet_id = s.network_interface.0.subnet_id
    }]

    content {
      subnet_id = target.value.subnet_id
      address   = target.value.address
    }
  }

  /*  target {
    subnet_id = var.subnet_id
    address   = yandex_compute_instance.app.*.network_interface.0.ip_address
  }
     target {
    subnet_id = var.subnet_id
    address   = yandex_compute_instance.app2.network_interface.0.ip_address
  }  */
}

resource "yandex_lb_network_load_balancer" "lb-app" {
  name = "lb-app"

  listener {
    name = "my-listener"
    port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app_group.id
    healthcheck {
      name = "http"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
