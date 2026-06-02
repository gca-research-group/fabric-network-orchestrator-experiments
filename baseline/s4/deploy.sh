#!/usr/bin/env bash
set -euo pipefail

# Prevent Git Bash/MSYS from rewriting Linux container paths such as /etc/...
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# Constants
OUTPUT_DIR="./b-s1"
DOMAIN="b-s1.com"

# Helper: Execute command in CA container
run_in_ca() {
  local org=$1
  shift
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker exec "ca.${org}.${DOMAIN}" "$@"
}

# Helper: Enroll CA Admin
enroll_ca_admin() {
  local org=$1
  echo "==> Enroll CA Admin (${org})"

  run_in_ca "${org}" fabric-ca-client enroll \
    -u "https://admin:adminpw@localhost:7054" \
    --caname "ca.${org}.${DOMAIN}" \
    --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
}

# Helper: Generate NodeOUs config
generate_nodeou_config() {
  local org=$1
  local type=$2 # peerOrganizations or ordererOrganizations
  echo "==> Generate Config YAML (${org} - ${type})"

  run_in_ca "${org}" sh -c "mkdir -p /etc/hyperledger/organizations/${type}/${org}.${DOMAIN}/msp && cat <<EOF_CFG > /etc/hyperledger/organizations/${type}/${org}.${DOMAIN}/msp/config.yaml
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.${org}.${DOMAIN}-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.${org}.${DOMAIN}-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.${org}.${DOMAIN}-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.${org}.${DOMAIN}-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF_CFG"
}

# Helper: Copy CA certs to organization structure
copy_ca_certs() {
  local org=$1
  local type=$2 # peerOrganizations or ordererOrganizations
  local base="/etc/hyperledger/organizations/${type}/${org}.${DOMAIN}"

  echo "==> Copy ${type} CA Certs (${org})"

  run_in_ca "${org}" sh -c "mkdir -p '${base}/msp/tlscacerts' && cp /etc/hyperledger/fabric-ca-server/ca-cert.pem '${base}/msp/tlscacerts/tlsca.${org}.${DOMAIN}.pem'"
  run_in_ca "${org}" sh -c "mkdir -p '${base}/tlsca' && cp /etc/hyperledger/fabric-ca-server/ca-cert.pem '${base}/tlsca/tlsca.${org}.${DOMAIN}-cert.pem'"
  run_in_ca "${org}" sh -c "mkdir -p '${base}/ca' && cp /etc/hyperledger/fabric-ca-server/ca-cert.pem '${base}/ca/ca.${org}.${DOMAIN}-cert.pem'"
  run_in_ca "${org}" sh -c "mkdir -p '${base}/msp/cacerts' && cp /etc/hyperledger/fabric-ca-server/ca-cert.pem '${base}/msp/cacerts/ca.${org}.${DOMAIN}-cert.pem'"
}

# Helper: Register identity
register_identity() {
  local org=$1
  local name=$2
  local secret=$3
  local type=$4 # peer, orderer, client, admin

  echo "==> Register ${name} (${org})"

  run_in_ca "${org}" fabric-ca-client register \
    --caname "ca.${org}.${DOMAIN}" \
    --id.name "${name}" \
    --id.secret "${secret}" \
    --id.type "${type}" \
    --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem
}

# Helper: Enroll MSP
enroll_msp() {
  local org=$1
  local name=$2
  local secret=$3
  local role=$4      # peers, orderers, or users
  local org_type=$5  # peerOrganizations or ordererOrganizations
  local id_full=$6   # e.g. peer0.org1.com or User1@org1.com

  local src="/var/hyperledger/${org}.${DOMAIN}/${role}/${id_full}/msp"
  local dest="/etc/hyperledger/organizations/${org_type}/${org}.${DOMAIN}/${role}/${id_full}/msp"

  echo "==> Generate ${name} MSP (${org})"

  # Important: repeated enrolments can leave multiple private keys in keystore.
  # Clean both locations before enrolling/copying.
  run_in_ca "${org}" sh -c "rm -rf '${src}' '${dest}'"

  run_in_ca "${org}" fabric-ca-client enroll \
    -u "https://${name}:${secret}@localhost:7054" \
    --caname "ca.${org}.${DOMAIN}" \
    --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem \
    -M "${src}"

  run_in_ca "${org}" sh -c "mkdir -p '${dest}/cacerts' '${dest}/keystore' '${dest}/signcerts' '${dest}/tlscacerts'"
  run_in_ca "${org}" sh -c "cp '${src}'/cacerts/* '${dest}/cacerts/ca.${org}.${DOMAIN}-cert.pem'"
  run_in_ca "${org}" sh -c "cp '${src}'/keystore/* '${dest}/keystore/priv_sk'"
  run_in_ca "${org}" sh -c "cp '${src}'/signcerts/* '${dest}/signcerts/cert.pem'"
  run_in_ca "${org}" sh -c "cp /etc/hyperledger/fabric-ca-server/ca-cert.pem '${dest}/tlscacerts/tlsca.${org}.${DOMAIN}.pem'"
  run_in_ca "${org}" sh -c "cp /etc/hyperledger/organizations/${org_type}/${org}.${DOMAIN}/msp/config.yaml '${dest}/config.yaml'"
}

# Helper: Enroll TLS
enroll_tls() {
  local org=$1
  local name=$2
  local secret=$3
  local role=$4      # peers, orderers, or users
  local org_type=$5  # peerOrganizations or ordererOrganizations
  local id_full=$6   # e.g. peer0.org1.com
  local type=$7      # server or client
  local host=$8      # e.g. peer0.org1.com

  local src="/var/hyperledger/${org}.${DOMAIN}/${role}/${id_full}/tls"
  local dest="/etc/hyperledger/organizations/${org_type}/${org}.${DOMAIN}/${role}/${id_full}/tls"

  echo "==> Generate ${name} TLS (${org})"

  # Clean repeated TLS enrolments to avoid multiple files in keystore/signcerts.
  run_in_ca "${org}" sh -c "rm -rf '${src}' '${dest}'"

  run_in_ca "${org}" fabric-ca-client enroll \
    --caname "ca.${org}.${DOMAIN}" \
    -u "https://${name}:${secret}@localhost:7054" \
    -M "${src}" \
    --enrollment.profile tls \
    --csr.hosts "${host}" \
    --csr.hosts localhost \
    --tls.certfiles /etc/hyperledger/fabric-ca-server/ca-cert.pem

  run_in_ca "${org}" sh -c "mkdir -p '${dest}'"
  run_in_ca "${org}" sh -c "cp '${src}'/tlscacerts/* '${dest}/ca.crt'"
  run_in_ca "${org}" sh -c "cp '${src}'/signcerts/* '${dest}/${type}.crt'"
  run_in_ca "${org}" sh -c "cp '${src}'/keystore/* '${dest}/${type}.key'"
}

share_tls() {
  local peer_count=$1
  shift

  local organizations=("$@")

  local ca_content=""
  local ca_files=()

  for organization in "${organizations[@]}"; do
    for ((i=0; i<peer_count; i++)); do

      ca_file="$OUTPUT_DIR/$organization.$DOMAIN/data/certificate-authority/organizations/peerOrganizations/$organization.$DOMAIN/peers/peer$i.$organization.$DOMAIN/tls/ca.crt"

      ca_files+=("$ca_file")

      ca_content+="$(<"$ca_file")"
      ca_content+=$'\n\n'
    done
  done

  for ca in "${ca_files[@]}"; do
    printf "%s" "$ca_content" > "$ca"
  done
}

compose_up() {
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker compose "$@" up --build -d
}

docker_exec() {
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker exec "$@"
}

echo "==> Start Certificate Authorities"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/ca.org1.${DOMAIN}.yml"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/ca.org2.${DOMAIN}.yml"

# --- Setup Org1 ---
enroll_ca_admin "org1"
generate_nodeou_config "org1" "peerOrganizations"
generate_nodeou_config "org1" "ordererOrganizations"
copy_ca_certs "org1" "peerOrganizations"
copy_ca_certs "org1" "ordererOrganizations"

register_identity "org1" "peer0" "peer0pw" "peer"
register_identity "org1" "orderer" "ordererpw" "orderer"
register_identity "org1" "user1" "user1pw" "client"
register_identity "org1" "orgadmin" "orgadminpw" "admin"

enroll_msp "org1" "peer0" "peer0pw" "peers" "peerOrganizations" "peer0.org1.${DOMAIN}"
enroll_msp "org1" "user1" "user1pw" "users" "peerOrganizations" "User1@org1.${DOMAIN}"
enroll_msp "org1" "orgadmin" "orgadminpw" "users" "peerOrganizations" "Admin@org1.${DOMAIN}"

enroll_msp "org1" "orderer" "ordererpw" "orderers" "ordererOrganizations" "orderer.org1.${DOMAIN}"
enroll_msp "org1" "orgadmin" "orgadminpw" "users" "ordererOrganizations" "Admin@org1.${DOMAIN}"
enroll_msp "org1" "user1" "user1pw" "users" "ordererOrganizations" "User1@org1.${DOMAIN}"

enroll_tls "org1" "orgadmin" "orgadminpw" "users" "ordererOrganizations" "Admin@org1.${DOMAIN}" "client" "orgadmin.org1.${DOMAIN}"
enroll_tls "org1" "user1" "user1pw" "users" "ordererOrganizations" "User1@org1.${DOMAIN}" "client" "user1.org1.${DOMAIN}"
enroll_tls "org1" "peer0" "peer0pw" "peers" "peerOrganizations" "peer0.org1.${DOMAIN}" "server" "peer0.org1.${DOMAIN}"
enroll_tls "org1" "orderer" "ordererpw" "orderers" "ordererOrganizations" "orderer.org1.${DOMAIN}" "server" "orderer.org1.${DOMAIN}"

# --- Setup Org2 ---
enroll_ca_admin "org2"
generate_nodeou_config "org2" "peerOrganizations"
generate_nodeou_config "org2" "ordererOrganizations"
copy_ca_certs "org2" "peerOrganizations"
copy_ca_certs "org2" "ordererOrganizations"

register_identity "org2" "peer0" "peer0pw" "peer"
register_identity "org2" "user1" "user1pw" "client"
register_identity "org2" "orgadmin" "orgadminpw" "admin"

enroll_msp "org2" "peer0" "peer0pw" "peers" "peerOrganizations" "peer0.org2.${DOMAIN}"
enroll_msp "org2" "user1" "user1pw" "users" "peerOrganizations" "User1@org2.${DOMAIN}"
enroll_msp "org2" "orgadmin" "orgadminpw" "users" "peerOrganizations" "Admin@org2.${DOMAIN}"

enroll_tls "org2" "peer0" "peer0pw" "peers" "peerOrganizations" "peer0.org2.${DOMAIN}" "server" "peer0.org2.${DOMAIN}"

share_tls 1 org1 org2

# --- Infrastructure ---
echo "==> Start Tools"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/tools.${DOMAIN}.yml"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/tools.${DOMAIN}.yml"

echo "==> Generate Genesis"
docker_exec "tools.org1.${DOMAIN}" sh -c "configtxgen -outputBlock /opt/gopath/src/github.com/hyperledger/fabric/channels/defaultchannel.block -profile DefaultProfile -channelID defaultchannel -configPath /opt/gopath/src/github.com/hyperledger/fabric/"

echo "==> Start Orderers"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/orderer.org1.${DOMAIN}.yml"

echo "==> Start Peers"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/couchdb.peer0.org1.${DOMAIN}.yml"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/peer0.org1.${DOMAIN}.yml"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/couchdb.peer0.org2.${DOMAIN}.yml"
compose_up -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/peer0.org2.${DOMAIN}.yml"

# --- Channel Join ---
echo "==> Join Orderers"
docker_exec "tools.org1.${DOMAIN}" sh -c "osnadmin channel join \
  --channelID defaultchannel \
  --config-block /opt/gopath/src/github.com/hyperledger/fabric/channels/defaultchannel.block \
  -o orderer.org1.${DOMAIN}:7053 \
  --ca-file /opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/ordererOrganizations/org1.${DOMAIN}/orderers/orderer.org1.${DOMAIN}/tls/ca.crt \
  --client-cert /opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/ordererOrganizations/org1.${DOMAIN}/orderers/orderer.org1.${DOMAIN}/tls/server.crt \
  --client-key /opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/ordererOrganizations/org1.${DOMAIN}/orderers/orderer.org1.${DOMAIN}/tls/server.key"

echo "Waiting 5 seconds for orderer readiness..."
sleep 5

echo "==> Fetch Genesis Block"
docker_exec "tools.org2.${DOMAIN}" peer channel fetch newest \
  /opt/gopath/src/github.com/hyperledger/fabric/channels/defaultchannel.block \
  -c defaultchannel \
  -o "orderer.org1.${DOMAIN}:7050" \
  --tls \
  --cafile "/opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/ordererOrganizations/org1.${DOMAIN}/orderers/orderer.org1.${DOMAIN}/tls/ca.crt"

echo "==> Join Peers"
docker_exec \
  -e CORE_PEER_ADDRESS="peer0.org1.${DOMAIN}:7051" \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_CERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/peerOrganizations/org1.${DOMAIN}/peers/peer0.org1.${DOMAIN}/tls/server.crt" \
  -e CORE_PEER_TLS_KEY_FILE="/opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/peerOrganizations/org1.${DOMAIN}/peers/peer0.org1.${DOMAIN}/tls/server.key" \
  -e CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/peerOrganizations/org1.${DOMAIN}/peers/peer0.org1.${DOMAIN}/tls/ca.crt" \
  -e CORE_PEER_LOCALMSPID="Org1MSP" \
  -e CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/org1.${DOMAIN}/peerOrganizations/org1.${DOMAIN}/users/Admin@org1.${DOMAIN}/msp" \
  "tools.org1.${DOMAIN}" peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/channels/defaultchannel.block

docker_exec \
  -e CORE_PEER_ADDRESS="peer0.org2.${DOMAIN}:7051" \
  -e CORE_PEER_TLS_ENABLED=true \
  -e CORE_PEER_TLS_CERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/org2.${DOMAIN}/peerOrganizations/org2.${DOMAIN}/peers/peer0.org2.${DOMAIN}/tls/server.crt" \
  -e CORE_PEER_TLS_KEY_FILE="/opt/gopath/src/github.com/hyperledger/fabric/org2.${DOMAIN}/peerOrganizations/org2.${DOMAIN}/peers/peer0.org2.${DOMAIN}/tls/server.key" \
  -e CORE_PEER_TLS_ROOTCERT_FILE="/opt/gopath/src/github.com/hyperledger/fabric/org2.${DOMAIN}/peerOrganizations/org2.${DOMAIN}/peers/peer0.org2.${DOMAIN}/tls/ca.crt" \
  -e CORE_PEER_LOCALMSPID="Org2MSP" \
  -e CORE_PEER_MSPCONFIGPATH="/opt/gopath/src/github.com/hyperledger/fabric/org2.${DOMAIN}/peerOrganizations/org2.${DOMAIN}/users/Admin@org2.${DOMAIN}/msp" \
  "tools.org2.${DOMAIN}" peer channel join -b /opt/gopath/src/github.com/hyperledger/fabric/channels/defaultchannel.block
