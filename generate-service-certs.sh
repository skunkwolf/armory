# generate-service-certs.sh
#!/bin/sh

# Set the working directory
WORKDIR="/root/ca"

# Check if the root CA certificate and key exist
if [ ! -f $WORKDIR/ca.crt ] || [ ! -f $WORKDIR/ca.key ]; then
  echo "Root CA certificate or key not found in $WORKDIR. Exiting."
  exit 1
fi

# Get input parameters
while getopts "c:o:u:" opt; do
  case $opt in
    c) COMMON_NAME="$OPTARG"
    ;;
    o) OUTPUT_NAME="$OPTARG"
    ;;
    u) ORG_UNIT="$OPTARG"
    ;;
    *) echo "Invalid option: -$OPTARG" >&2
       exit 1
    ;;
  esac
done

# Set default values if parameters were not provided
: "${COMMON_NAME:=Default Common Name}"
: "${OUTPUT_NAME:=service}"
: "${ORG_UNIT:=Default Organizational Unit}"

# Generate a private key for the service
openssl genpkey -algorithm RSA -out $WORKDIR/${OUTPUT_NAME}.key

# Create a certificate signing request (CSR) for the service
openssl req -key $WORKDIR/${OUTPUT_NAME}.key -new -out $WORKDIR/${OUTPUT_NAME}.csr -subj "/CN=${COMMON_NAME}/OU=${ORG_UNIT}"

# Sign the CSR with the root CA
openssl x509 -req -in $WORKDIR/${OUTPUT_NAME}.csr -CA $WORKDIR/ca.crt -CAkey $WORKDIR/ca.key -CAcreateserial -out $WORKDIR/${OUTPUT_NAME}.crt -days 365

# Optionally, print the generated service certificate
# openssl x509 -in $WORKDIR/${OUTPUT_NAME}.crt -text -noout
