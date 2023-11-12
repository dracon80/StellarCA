FROM mcr.microsoft.com/devcontainers/base:debian

#Install openSSL
RUN apt-get update && apt-get install -y openssl curl && apt-get clean

#Instal yq yaml commandline tool
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

#Install K8S root certficate.
COPY .k8s/ca.crt /usr/share/ca-certificates/k8s.cert
RUN update-ca-certificates

#Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN rm -f kubectl

#Copy the kubernetes Servie Account Token and settings into container
COPY .k8s/dev-sa-token /var/run/secrets/kubernetes.io/serviceaccount/token
COPY .k8s/ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
COPY .k8s/namespace /var/run/secrets/kubernetes.io/serviceaccount/namespace