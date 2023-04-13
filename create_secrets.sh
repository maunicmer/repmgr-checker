#!/bin/bash

source secrets.txt

docker secret rm smtp_user;  printf "$SMTP_USER" | docker secret create  smtp_user -
docker secret rm smtp_password;  printf "$SMTP_PASSWORD" | docker secret create smtp_password -