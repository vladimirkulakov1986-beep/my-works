# Домашнее задание к занятию "`Отказоустойчивость в облаке`" - `Kulakov Vladimir`


### Инструкция по выполнению домашнего задания

   1. Сделайте `fork` данного репозитория к себе в Github и переименуйте его по названию или номеру занятия, например, https://github.com/имя-вашего-репозитория/git-hw или  https://github.com/имя-вашего-репозитория/7-1-ansible-hw).
   2. Выполните клонирование данного репозитория к себе на ПК с помощью команды `git clone`.
   3. Выполните домашнее задание и заполните у себя локально этот файл README.md:
      - впишите вверху название занятия и вашу фамилию и имя
      - в каждом задании добавьте решение в требуемом виде (текст/код/скриншоты/ссылка)
      - для корректного добавления скриншотов воспользуйтесь [инструкцией "Как вставить скриншот в шаблон с решением](https://github.com/netology-code/sys-pattern-homework/blob/main/screen-instruction.md)
      - при оформлении используйте возможности языка разметки md (коротко об этом можно посмотреть в [инструкции  по MarkDown](https://github.com/netology-code/sys-pattern-homework/blob/main/md-instruction.md))
   4. После завершения работы над домашним заданием сделайте коммит (`git commit -m "comment"`) и отправьте его на Github (`git push origin`);
   5. В личном кабинете прикрепите и отправьте ссылку на решение в виде md-файла в вашем Github.
   6. Любые вопросы по выполнению заданий спрашивайте в разделе “Вопросы по заданию” в личном кабинете.
   
Желаем успехов в выполнении домашнего задания!
   
### Дополнительные материалы, которые могут быть полезны для выполнения задания

1. [Руководство по оформлению Markdown файлов](https://gist.github.com/Jekins/2bf2d0638163f1294637#Code)



### Задание 1

```terraform {
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
```

![balance](https://github.com/vladimirkulakov1986-beep/my-works/blob/main/Linux/%D0%9E%D1%82%D0%BA%D0%B0%D0%B7%D0%BE%D1%83%D1%81%D1%82%D0%BE%D0%B9%D1%87%D0%B8%D0%B2%D0%BE%D1%81%D1%82%D1%8C%20%D0%B2%20%D0%BE%D0%B1%D0%BB%D0%B0%D0%BA%D0%B5/img/balance.png)
![nginx](https://github.com/vladimirkulakov1986-beep/my-works/blob/main/Linux/%D0%9E%D1%82%D0%BA%D0%B0%D0%B7%D0%BE%D1%83%D1%81%D1%82%D0%BE%D0%B9%D1%87%D0%B8%D0%B2%D0%BE%D1%81%D1%82%D1%8C%20%D0%B2%20%D0%BE%D0%B1%D0%BB%D0%B0%D0%BA%D0%B5/img/nginx.png)




