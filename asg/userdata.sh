#!/bin/bash -x

yum install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

docker run -d --name sample-app --restart always --pull always -p 8080:8080 hmoon630/sample-fastapi:latest


cat << EOF > /tmp/dockerenv
PORT=8888
UPSTREAM_ENDPOINT=http://localhost:8080
IGNOREPATH=/favicon.ico
IGNORE_HEALTHCHECK=1
EOF

sudo docker run -d --network host --env-file /tmp/dockerenv --name proxy public.ecr.aws/g1s2t7w5/sampler:latest