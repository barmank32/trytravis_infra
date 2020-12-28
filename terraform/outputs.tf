output "external_ip_address_app" {
  value = yandex_compute_instance.app.*.network_interface.0.nat_ip_address
}

/* output "external_ip_address_app2" {
  value = yandex_compute_instance.app2.network_interface.0.nat_ip_address
} */

output "balancer_ip_address" {
  value = [for ex_ip in yandex_lb_network_load_balancer.lb-app.listener : ex_ip.external_address_spec].0
}
