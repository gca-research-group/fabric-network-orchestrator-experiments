OUTPUT_DIR="./b-s3"
DOMAIN="b-s3.com"

compose_down() {
  MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL="*" docker compose "$@" down
}

compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/tools.org1.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/peer0.org1.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/couchdb.peer0.org1.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/orderer.org1.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org1.${DOMAIN}/ca.org1.${DOMAIN}.yml"

compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/tools.org2.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/peer0.org2.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/couchdb.peer0.org2.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org2.${DOMAIN}/ca.org2.${DOMAIN}.yml"

compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org3.${DOMAIN}/tools.org3.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org3.${DOMAIN}/peer0.org3.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org3.${DOMAIN}/couchdb.peer0.org3.${DOMAIN}.yml"
compose_down -f "${OUTPUT_DIR}/network.yml" -f "${OUTPUT_DIR}/org3.${DOMAIN}/ca.org3.${DOMAIN}.yml"