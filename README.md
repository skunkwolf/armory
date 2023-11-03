# Armory: Skunkwolf Certificate & Key Management

![Skunkwolf Key Management](./images/skunkwolf-keys.png)

Armory is a Docker-based utility designed to facilitate the creation and management of certificates and keys, including the generation of a self signed root Certificate Authority (CA). The service certificates are then signed by that root CA. This first version generates and stores the keys within the file system of the host machine. Future versions will provide more robust key management capabilities. 

## Table of Contents
- [Getting Started](#getting-started)
- [Generating the CA Certificate](#generating-the-ca-certificate)
- [Adding the CA Certificate to your Keychain](#adding-the-ca-certificate-to-your-keychain)
- [Access Certificates on Local Machine](#access-certificates-on-local-machine)
- [NATS Service Certificates](#nats-service-certificates)
- [Cleanup](#cleanup)
- [Ensuring the Certificates are Trusted](#ensuring-the-certificates-are-trusted)
- [Contributing](#contributing)
- [License](#license)

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites
- Docker installed on your local machine.
- Basic knowledge of Docker and command-line operations.

### Clone the Repository
```bash
cd </path/to/your/desired/project/directory>
git clone https://github.com/skunkwolf/armory.git
cd <repository-directory>
```

### Build Docker Image

Build the Docker image using the following command:

```docker
docker build -t skunkwolf-ca .
```

### Run Docker Container

Run a Docker container from the image, mounting a volume from your local machine to the container. This volume will be used to store and access the generated certificates on your local machine.

```docker
docker run -it --name skunkwolf-ca -v $(pwd)/ca:/root/ca skunkwolf-ca sh
```

[Back to Top](#table-of-contents)

## Generating the CA Certificate

The first step is to create a self signed certificate that will be used to sign the certicifates we'll need to use for the Skunkwolf. In a production environment the service certificates should be signed by a trusted Certificate Authority. For the purposes of this project we are acting as that trusted CA. This will require us to add the root CA to our trusted certificates, which we'll do in a later step. 

### Root CA Certificate

The following commands should be executed inside the container which will generate the root CA certificate and key. This process only needs to be completed once as the same root certificate will be used to sign all of the service certificates generated for the Skunkwolf.

When creating the key you will be promoted to provide a PEM Passphrase. This should be treated with the upmost security as additional keys can be signed with the root CA if you have this PEM Passphrase. It will also be used to sign the `skunkwolf-ca.crt` as we'll see below. 

```bash
# Step 1: export the working directory
export WORKDIR="path/to/your/project"

# Step 2: Generate the private key for the root CA
openssl genpkey -algorithm RSA -out $WORKDIR/ca/skunkwolf-ca.key -aes256 -pkeyopt rsa_keygen_bits:4096

# Step 3: Generate the root CA certificate
openssl req -key $WORKDIR/ca/skunkwolf-ca.key -new -x509 -days 3650 -out $WORKDIR/ca/skunkwolf-ca.crt -subj "/CN=Skunkwolf CA/O=Skunkwolf /C=US" -extensions v3_ca -config /etc/ssl/openssl.cnf -sha256
```

[Back to Top](#table-of-contents)

## Access Certificates on Local Machine

You should now have the `skunkwolf-ca.key` and `skunkwolf-ca.crt` available in the `$WOKDIR/ca` directory. The `skunkwolf-ca.crt` can now be added to your local trust store. 

[Back to Top](#table-of-contents)

## Adding the CA Certificate to your Keychain

We'll be exposing some http services to our host machine and requiring TLS for those connections. For that reason we'll need to add the self-signed Certificate Authority (CA) certificate to our MacBook can be achieved in a few steps:

1. Double-click on the CA certificate file. This will open it in the Keychain Access utility.
    * You'll be prompted to add the certificate to your keychain. 
    * Select a keychain to add it to; adding it to your login keychain is usually the simplest choice.
2. Trust the CA Certificate:
    * In the Keychain Access utility, find the certificate you just added. It will be in the keychain you added it to, under the Certificates category.
    * Double-click on the certificate to open it.
    * Expand the "Trust" section.
    * Set "When using this certificate" to "Always Trust".
    * Close the certificate window. You'll be prompted for your admin password to update the certificate settings.

For alternative environments the options for trusting this certificate can be found here: [Ensuring the Certificates are Trusted](#ensuring-the-certificates-are-trusted)

[Back to Top](#table-of-contents)

## NATS Service Certificates

Once initial setup is complete a script can be used within the Docker container to generate the keys, certificate signing requests (CSRs), and certificates that the Skunkwolf NATS services will use to establish TLS connections. In order to sign the CSR and create a certificate the CA certificate creted in the steps above is needed.

This script automates the process of generating the NATS service certificates and ensures that the necessary root CA certificate and key exist before proceeding.

> **_NOTE:_** Currently only one script has been defined 'generate-nats-certs.sh' which is based on the the specific requirements for NATS. Other scripts will be included in the future as needed by the Skunkwolf. 

#### Usage:

Two different certificates and keys will be needed for the NATS cluseter. The first secures communication between the nodes in the cluster and the second seecures client connections to the cluster. These two certificates can be created with the collowing commands: 

```bash
generate-nats-certs.sh -c "nats-cluster" -o nats-cluster -u "skunkwolf" -s "DNS:nats-headless.default.svc.cluster.local, DNS:*.nats-headless.default.svc.cluster.local"
generate-nats-certs.sh -c "nats-cluster-route" -o nats-cluster-route -u "skunkwolf" -s "DNS:nats-headless.default.svc.cluster.local, DNS:*.nats-headless.default.svc.cluster.local"
```

Both have the same Subject Alternative Name Definition (SAN). If you'd like to use a different configuration see the details on how the script works below: 

#### Parameters:

- `-c`: Common Name (CN) for the service certificate.
- `-o`: Base name for the output files. The script will generate `${OUTPUT_NAME}.key`, `${OUTPUT_NAME}.csr`, and `${OUTPUT_NAME}.crt`.
- `-u`: Organizational Unit (OU) for the service certificate.
- `-s`: Subject Alternative Name (SAN) for the certificate. 

#### Default Values:

If parameters are not provided, the script uses the following default values:

- Common Name: "nats-cluster"
- Output Name: "nats-cluster"
- Subject Alternative Name: "DNS:nats-headless.default.svc.cluster.local, DNS:*.nats-headless.default.svc.cluster.local"
- Organizational Unit: "skunkwolf"

#### Steps Performed by the Script:

1. **Working Directory Setup**: Sets the working directory to `/root/ca` where the root CA certificate and key are expected to be located.

2. **Root CA Verification**: Checks for the existence of the root CA certificate and key. If either is missing, the script exits.

3. **Parameter Parsing**: Parses command-line arguments for the Common Name, Output Name, and Organizational Unit.

4. **Private Key Generation**: Generates a private key for the service using the RSA algorithm.

5. **Certificate Signing Request (CSR) Creation**: Creates a Certificate Signing Request using the provided or default Common Name and Organizational Unit.

6. **Certificate Signing**: Signs the CSR with the root CA certificate and key, generating a service certificate valid for 365 days.

7. **(Optional) Certificate Printing**: Uncomment the last line of the script if you wish to print the generated service certificate to the console.

#### Output:

The script generates three files for each invokation:

- Private Key: `${OUTPUT_NAME}.key`
- Certificate Signing Request: `${OUTPUT_NAME}.csr`
- Service Certificate: `${OUTPUT_NAME}.crt`

These files are stored in the working directory `/root/ca` and can be accessed on your local machine via the mounted volume when running the Docker container.

to inspect the service certificates you can use this command: 

```bash
openssl x509 -in /root/ca/${OUTPUT_NAME}.crt -text -noout
```

---

[Back to Top](#table-of-contents)




## Cleanup

You can stop and remove the container once you've generated the necessary certificates:

```bash
docker stop skunkwolf-ca && docker rm skunkwolf-ca
```

[Back to Top](#table-of-contents)

## Ensuring the Certificates are Trusted 
To ensure that the service certificates are trusted, you'll need to add the root certificate to the trusted certificate store on each machine that will be interacting with the service. The process varies slightly depending on the operating system. Here's how you could do it on a few common systems:

### 1. **Linux**:

On many Linux systems, the trusted certificates are stored in a directory such as `/usr/local/share/ca-certificates/`. You can add a new trusted root certificate by:

1. Copying the root certificate file to this directory.
```bash
sudo cp /path/to/your/root.crt /usr/local/share/ca-certificates/root.crt
```

2. Updating the certificate trust store.
```bash
sudo update-ca-certificates
```

### 2. **Windows**:

On Windows, you would typically use the Microsoft Management Console (MMC) to add a trusted root certificate:

1. Press `Win + R`, type `mmc`, and press `Enter`.
2. Go to `File` > `Add/Remove Snap-in`, select `Certificates`, click `Add`, select `Computer account`, and click `Next` > `Finish` > `OK`.
3. Expand `Certificates (Local Computer)`, right-click on `Trusted Root Certification Authorities` > `All Tasks` > `Import`.
4. Follow the wizard to import the root certificate.

### 3. **macOS**:

On macOS, you can use the Keychain Access utility to add a trusted root certificate:

1. Open `Keychain Access`.
2. Drag the root certificate file into the `Keychain Access` window.
3. Right-click on the imported certificate, select `Get Info`, expand the `Trust` section, and set `When using this certificate` to `Always Trust`.

### 4. **Programmatically**:

In some scenarios, you might be interacting with services in a programming environment. In such cases, you might need to specify the root certificate programmatically. For example, in Go, you might create a custom `http.Client` with a custom `tls.Config` that includes the root certificate.

```go
import (
	"crypto/tls"
	"crypto/x509"
	"io/ioutil"
	"net/http"
)

func main() {
	caCert, err := ioutil.ReadFile("/path/to/your/root.crt")
	if err != nil {
		log.Fatal(err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: caCertPool,
			},
		},
	}

	// ...
}
```

[Back to Top](#table-of-contents)

## Contributing

If you wish to contribute to this project, please feel free to fork the repo, create a new branch, commit your changes, and open a pull request.

[Back to Top](#table-of-contents)

## License

This project is licensed under the MIT License - see the LICENSE.md file for details.

[Back to Top](#table-of-contents)