# this is specifically for created certificates for the NATS cluster as per the recommendations here: 
# https://docs.nats.io/running-a-nats-service/configuration/securing_nats/tls
# generate-nats-certs.sh
#!/bin/sh

# Set the working directory
WORKDIR="/root/ca"

# Check if the root CA certificate and key exist
if [ ! -f $WORKDIR/skunkwolf-ca.crt ] || [ ! -f $WORKDIR/skunkwolf-ca.key ]; then
  echo "Root CA certificate or key not found in $WORKDIR. Exiting."
  exit 1
fi

# Get input parameters
while getopts "c:o:u:s:" opt; do
  case $opt in
    c) COMMON_NAME="$OPTARG"
    ;;
    o) OUTPUT_NAME="$OPTARG"
    ;;
    u) ORG_UNIT="$OPTARG"
    ;;
    s) SAN="$OPTARG"
    ;;
    *) echo "Invalid option: -$OPTARG" >&2
       exit 1
    ;;
  esac
done

# Set default values if parameters were not provided
: "${COMMON_NAME:=nats-cluster}"
: "${OUTPUT_NAME:=nats-cluster}"
: "${ORG_UNIT:=skunkwolf}"
: "${SAN:=DNS:nats-headless.default.svc.cluster.local, DNS:*.nats-headless.default.svc.cluster.local}"

# Generate a private key for the service
openssl genpkey -algorithm RSA -out $WORKDIR/${OUTPUT_NAME}.key

# Create a certificate signing request (CSR) for the service
openssl req -key $WORKDIR/${OUTPUT_NAME}.key -new -out $WORKDIR/${OUTPUT_NAME}.csr -subj "/CN=${COMMON_NAME}/OU=${ORG_UNIT}"

# Create a temporary OpenSSL config file
cat > $WORKDIR/${OUTPUT_NAME}-openssl.cnf <<EOF
[ v3_ext ]
subjectAltName=$SAN
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
basicConstraints = CA:FALSE
EOF

# Sign the CSR with the root CA, including the SAN
openssl x509 -req -in $WORKDIR/${OUTPUT_NAME}.csr -CA $WORKDIR/skunkwolf-ca.crt -CAkey $WORKDIR/skunkwolf-ca.key -CAcreateserial -out $WORKDIR/${OUTPUT_NAME}.crt -days 365 -extfile $WORKDIR/${OUTPUT_NAME}-openssl.cnf -extensions v3_ext

# Optionally, print the generated service certificate
# openssl x509 -in $WORKDIR/${OUTPUT_NAME}.crt -text -noout

# (Optional) Remove the temporary OpenSSL config file
rm $WORKDIR/${OUTPUT_NAME}-openssl.cnf
