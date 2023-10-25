# Dockerfile
FROM alpine:latest

# Install OpenSSL
RUN apk --no-cache add openssl

# Set up a working directory
WORKDIR /root/ca

# Copy the script into the Docker image
COPY generate-service-certs.sh /usr/local/bin/generate-service-certs.sh

# Copy the openssl.cnf configuration file into the Docker image
COPY openssl.cnf /etc/ssl/openssl.cnf

# Make the script executable
RUN chmod +x /usr/local/bin/generate-service-certs.sh
