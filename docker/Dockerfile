
ARG ENVIRONMENT="production"

########################################################
# Base Image
########################################################
FROM alpine:3.18 as stellarca_base
RUN apk add --no-cache ca-certificates openssl curl envsubst

#Instal yq yaml commandline tool
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

#Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && rm -f kubectl

#Create user Stellar and nginx group so that nginx container can read files created
RUN addgroup -g 101 nginx && adduser -G nginx -u 1000 stellar -D

#Create stellar system folders
WORKDIR /app
ENV PATH="${PATH}:/app"
RUN mkdir -p /var/ca /var/www/html /etc/ca /app/tmp

########################################################
# Development Build
########################################################
FROM stellarca_base as build_development
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
#Copy in the project files
ONBUILD COPY stellarca/* ./

########################################################
# Final build stage
# Copy in the code and setup the entrypoint
########################################################
FROM build_${ENVIRONMENT}
LABEL maintainer="dracon80 https://github.com/dracon80"
LABEL github="https://github.com/dracon80/StellarCA"

#Assign permissions
RUN chown stellar:nginx -R /app /var/www/html /var/ca /etc/ca \
    && chmod 770 /app /var/ca /etc/ca \
    && chown stellar:nginx -R /var/www/html \
    && chmod 774 /var/www/html

VOLUME ["/var/ca", "/var/www/html"]
EXPOSE 9801/tcp

USER 1000
ENTRYPOINT [ "/app/entrypoint.sh" ]
CMD ["stellar"]