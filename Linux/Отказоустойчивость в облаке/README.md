# Домашнее задание к занятию "`Кластеризация и балансировка нагрузки`" - `Kulakov Vladimir`


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


![задание1](https://github.com/vladimirkulakov1986-beep/zabbix-hw/blob/main/Otkaz/img/Zadanie1.png)




### Задание 2

```
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    http                # Включаем 7 уровень (L7)
    option  httplog             # Логирование HTTP-запросов
    option  dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s

frontend http_frontend
    bind *:80
    mode http
    
    # ACL: проверяем, что заголовок Host равен "example.local"
    acl is_example_domain hdr(host) -i example.local
    
    # Перенаправляем на бэкенд только если условие ACL выполняется
    use_backend python_http_servers if is_example_domain
    
    # Если запрос пришел БЕЗ домена (или по IP), отдаем HTTP 403 Forbidden
    http-request deny deny_status 403 if !is_example_domain

backend python_http_servers
    mode http
    balance roundrobin          # В HAProxy weighted-балансировка задается через обычный roundrobin + веса
    
    # Настройка серверов с указанными весами (2, 3, 4)
    server server1 127.0.0.1:8001 weight 2 check
    server server2 127.0.0.1:8002 weight 3 check
    server server3 127.0.0.1:8003 weight 4 check

```

![задание2](https://github.com/vladimirkulakov1986-beep/zabbix-hw/blob/main/Otkaz/img/Zadanie2.png)
