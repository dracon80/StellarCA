
ARG ENVIRONMENT="production"

########################################################
# Base Image
########################################################
FROM alpine:3.18 as stellarca_base
RUN apk add --no-cache ca-certificates openssl curl envsubst

#Instal yq yaml commandline tool
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

#Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
RUN rm -f kubectl


########################################################
# Development Build
########################################################
FROM stellarca_base as build_development
#COPY IN THE SECRETS TO ALLOW KUBERNETES API ACCESS IN DEV

#Copy the kubernetes Servie Account Token and settings into container
ONBUILD COPY .k8s/sa-token /var/run/secrets/kubernetes.io/serviceaccount/token
ONBUILD COPY .k8s/ca.crt /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
ONBUILD COPY .k8s/namespace /var/run/secrets/kubernetes.io/serviceaccount/namespace

#Install K8S root certficate.
ONBUILD COPY .k8s/ca.crt /usr/share/ca-certificates/k8s.cert
ONBUILD RUN update-ca-certificates

########################################################
# Production build
########################################################
FROM stellarca_base as build_production
#NOTHING TO DO HERE REALY

########################################################
# Final build stage
# Copy in the code and setup the entrypoint
########################################################
FROM build_${ENVIRONMENT}
LABEL maintainer="dracon80 https://github.com/dracon80"
LABEL github="https://github.com/dracon80/StellarCA"
VOLUME ["/var/ca", "/var/www/html", "/app/config.yaml"]
EXPOSE 9801/tcp

#Create user for Container
RUN adduser -u 101 stellar stellar -D

#Create stellar system folders
WORKDIR /app
RUN mkdir -p /var/ca /var/www/html /etc/ca /app/tmp

#Copy in init script and config
COPY stellarca/init.sh ./
COPY stellarca/openssl.conf ./

#Assign permissions
RUN chown stellar:stellar -R /app /var/www/html /var/ca /etc/ca /app/
RUN chmod 774 /var/www/html
RUN chmod 770 /app /var/ca /etc/ca
RUN chmod +x /app/init.sh

USER stellar
ENTRYPOINT [ "/app/init.sh" ]
CMD ["stellarca"]