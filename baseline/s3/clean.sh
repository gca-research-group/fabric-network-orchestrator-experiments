OUTPUT_DIR="./b-s3"
DOMAIN="b-s3.com"

clean() {
    rm -r "${OUTPUT_DIR}/$@.${DOMAIN}/data"
}

clean org1
clean org2