terraform {
  required_version = ">= 0.13"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.61.0"
    }
  }
}

provider "yandex" {
  cloud_id  = "b1gkscvdqklv7om1a7ge"
  folder_id = "b1gvhidc1q42amlros7r"
  zone      = "ru-central1-a"
}

# 1. Считываем данные существующей стандартной подсети
data "yandex_vpc_subnet" "existing_subnet" {
  name = "default-ru-central1-a"
}

# Автоматический поиск актуального ID официального образа Ubuntu 22.04 LTS
data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

# 2. Создание 2 идентичных ВМ с помощью аргумента count
resource "yandex_compute_instance" "web" {
  count       = 2
  name        = "web-server-${count.index + 1}"
  platform_id = "standard-v2" # Используем платформу v2

  resources {
    cores         = 2  # Устанавливаем обязательные 2 ядра
    memory        = 2  # Устанавливаем 2 ГБ RAM
    core_fraction = 20 # Позволяет экономить ресурсы
  }

  # ДОБАВЛЕНО: делаем машины прерывистыми, чтобы обойти жесткие квоты vCPU аккаунта
  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.existing_subnet.id
    nat       = true
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      package_update: true
      packages:
        - nginx
      runcmd:
        - systemctl enable nginx
        - systemctl start nginx
    EOF
  }
}

# 3. Создание Target Group (Целевой группы)
resource "yandex_lb_target_group" "tg" {
  name = "web-target-group"

  dynamic "target" {
    for_each = yandex_compute_instance.web
    content {
      subnet_id = data.yandex_vpc_subnet.existing_subnet.id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

# 4. Создание Сетевого балансировщика
resource "yandex_lb_network_load_balancer" "lb" {
  name = "web-balancer"

  listener {
    name = "http-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg.id

    healthcheck {
      name = "http-healthcheck"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
