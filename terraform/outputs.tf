output "external_ip_address_app" {
  value = yandex_compute_instance.app.*.network_interface.0.nat_ip_address
}

output "external_ip_address_lb" {
  value = yandex_lb_network_load_balancer.reddit_app_lb.listener.*.external_address_spec[0].*.address
}

output "external_port_lb" {
  value = yandex_lb_network_load_balancer.reddit_app_lb.listener.*.port
}

output "target_port_lb" {
  value = yandex_lb_network_load_balancer.reddit_app_lb.listener.*.target_port
}
