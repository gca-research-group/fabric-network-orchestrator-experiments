OUTPUT_DIR="./b-s1"
DOMAIN="b-s1.com"

clean() {
    rm -r "${OUTPUT_DIR}/$@.${DOMAIN}/data"
}

clean org1
clean org2