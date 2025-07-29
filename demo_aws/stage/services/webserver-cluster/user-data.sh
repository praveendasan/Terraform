#!/bin/bash

yum update -y
yum install -y busybox
mkdir -p /www
echo "<h1>Hello from BusyBox on port ${server_port}!</h1> ${server_port}" > /www/index.html
busybox httpd -f -p 8080 -h /www &