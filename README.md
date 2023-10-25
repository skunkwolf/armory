![Skunkwolf Key Management](./images/skunkwolf-keys.png)


# Armory: Skunkwolf Certificate & Key Management

Armory is a Docker-based utility designed to facilitate the management of certificates and keys, including the generation of root CA certificates and service certificates signed by a root CA. This first version simply generates and stores the keys within the file system of the host machine. A future version will also provide more robust key management capabilities. 

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

- Docker installed on your local machine.
- Knowledge of Docker basics and command-line operations.

### Clone the Repository

Clone this repository to your local machine to get started.

```bash
git clone https://github.com/skunkwolf/armory.git
cd <repository-directory>
```

### Build Docker Image

Build the Docker image using the following command:

```bash
docker build -t skunkwolf-ca .
```

### Run Docker Container

Run a Docker container from the image, mounting a volume from your local machine to the container. This volume will be used to store and access the generated certificates on your local machine.

```bash
docker run -it --name skunkwolf-ca -v $(pwd)/ca:/root/ca skunkwolf-ca sh
```

## Generating Certificates

### Root CA Certificate

If a Root CA Certificate doesn't already exist, execute the following commands inside the container to generate the root CA certificate and key:

```bash
# Generate the private key for the root CA
openssl genpkey -algorithm RSA -out $WORKDIR/skunkwolf-ca.key -aes256 -pkeyopt rsa_keygen_bits:4096

# Generate the root CA certificate
openssl req -key $WORKDIR/skunkwolf-ca.key -new -x509 -days 3650 -out $WORKDIR/ca.crt -subj "/CN=Skunkwolf CA/O=Skunkwolf /C=US" -extensions v3_ca -config /etc/ssl/openssl.cnf -sha256
```

### Service Certificates

This script can be run inside the container to generate service certificates signed by the root CA previously generated:

```bash
generate-service-certs.sh -c "Your Common Name" -o your_service -u "Your Organizational Unit"
```

---

This script automates the process of generating service certificates signed by a pre-existing Root Certificate Authority (CA). It ensures that the necessary root CA certificate and key exist before proceeding with the generation of service-specific certificates.

#### Usage:

```bash
generate-service-certs.sh -c "Your Common Name" -o your_service -u "Your Organizational Unit"
```

#### Parameters:

- `-c`: Common Name (CN) for the service certificate.
- `-o`: Base name for the output files. The script will generate `${OUTPUT_NAME}.key`, `${OUTPUT_NAME}.csr`, and `${OUTPUT_NAME}.crt`.
- `-u`: Organizational Unit (OU) for the service certificate.

#### Default Values:

If parameters are not provided, the script uses the following default values:

- Common Name: "skunkwolf-service"
- Output Name: "skunkwolf-service"
- Organizational Unit: "skunkwolf"

#### Steps Performed by the Script:

1. **Working Directory Setup**:
   - Sets the working directory to `/root/ca` where the root CA certificate and key are expected to be located.

2. **Root CA Verification**:
   - Checks for the existence of the root CA certificate and key. If either is missing, the script exits.

3. **Parameter Parsing**:
   - Parses command-line arguments for the Common Name, Output Name, and Organizational Unit.

4. **Private Key Generation**:
   - Generates a private key for the service using the RSA algorithm.

5. **Certificate Signing Request (CSR) Creation**:
   - Creates a Certificate Signing Request using the provided or default Common Name and Organizational Unit.

6. **Certificate Signing**:
   - Signs the CSR with the root CA certificate and key, generating a service certificate valid for 365 days.

7. **(Optional) Certificate Printing**:
   - Uncomment the last line of the script if you wish to print the generated service certificate to the console.

#### Output:

The script generates three files for each service:

- Private Key: `${OUTPUT_NAME}.key`
- Certificate Signing Request: `${OUTPUT_NAME}.csr`
- Service Certificate: `${OUTPUT_NAME}.crt`

These files are stored in the working directory `/root/ca` and can be accessed on your local machine via the mounted volume when running the Docker container.

---

This description provides a detailed explanation of what the script does, how to use it, and the files it generates, making it easier for others to understand its functionality and usage.

## Access Certificates on Local Machine

Exit the Docker container, and you'll find the generated certificates in the `ca` directory on your local machine.

## Cleanup

You can stop and remove the container once you've generated the necessary certificates:

```bash
docker stop skunkwolf-ca && docker rm skunkwolf-ca
```

## Contributing

If you wish to contribute to this project, please feel free to fork the repo, create a new branch, commit your changes, and open a pull request.

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.

---