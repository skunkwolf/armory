![Skunkwolf Key Management](./images/skunkwolf-keys.png)


# Armory: Skunkwolf Certificate & Key Management

Armory is a Docker-based utility designed to facilitate the management of certificates and keys, including the generation of root CA certificates and service certificates signed by a root CA.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- Docker installed on your local machine.
- Knowledge of Docker basics and command-line operations.

### Clone the Repository

Clone this repository to your local machine to get started.

```bash
git clone <repository-url>
cd <repository-directory>
```

### Build Docker Image

Build the Docker image using the following command:

```bash
docker build -t my-ca .
```

### Run Docker Container

Run a Docker container from the image, mounting a volume from your local machine to the container. This volume will be used to store and access the generated certificates on your local machine.

```bash
docker run -it --name ca-container -v $(pwd)/ca:/root/ca my-ca sh
```

## Generating Certificates

### Root CA Certificate

If a Root CA Certificate doesn't already exist, execute the following commands inside the container to generate the root CA certificate and key:

```bash
# Generate the private key for the root CA
openssl genpkey -algorithm RSA -out $WORKDIR/ca.key -aes256 -pkeyopt rsa_keygen_bits:4096

# Generate the root CA certificate
openssl req -key $WORKDIR/ca.key -new -x509 -days 3650 -out $WORKDIR/ca.crt -subj "/CN=Skunkwolf CA/O=Skunkwolf Corp/C=US" -extensions v3_ca -config /etc/ssl/openssl.cnf -sha256
```

### Service Certificates

Run the script inside the container to generate service certificates signed by the root CA:

```bash
generate-service-certs.sh -c "Your Common Name" -o your_service -u "Your Organizational Unit"
```

## Access Certificates on Local Machine

Exit the Docker container, and you'll find the generated certificates in the `ca` directory on your local machine.

## Cleanup

You can stop and remove the container once you've generated the necessary certificates:

```bash
docker stop ca-container && docker rm ca-container
```

## Contributing

If you wish to contribute to this project, please feel free to fork the repo, create a new branch, commit your changes, and open a pull request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.

---

This revised `README.md` provides a more structured and detailed guide on how to use the project, with a clear breakdown of steps, code snippets, and additional sections for contributing and licensing. It should provide a more complete overview and usage guide for anyone accessing your GitHub repository.