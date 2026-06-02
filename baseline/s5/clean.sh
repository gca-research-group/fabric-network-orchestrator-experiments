OUTPUT_DIR="./b-s5"
DOMAIN="b-s5.com"

clean() {
    rm -r "${OUTPUT_DIR}/$@.${DOMAIN}/data"
}

clean org1
clean org2