resource "yandex_lb_target_group" "reddit_app_tg" {
  name      = "reddit-app-tg"
  region_id = "ru-central1"

  dynamic target {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
}

resource "yandex_lb_network_load_balancer" "reddit_app_lb" {
  name = "reddit-app-lb"

  listener {
    name        = "reddit-app-listener"
    port        = 80
    target_port = 9292
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.reddit_app_tg.id

    healthcheck {
      name = "app-http-hc"
      http_options {
        port = 9292
        path = "/"
      }
    }
  }
}
