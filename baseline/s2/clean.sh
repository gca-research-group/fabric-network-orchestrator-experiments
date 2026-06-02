OUTPUT_DIR="./b5o2p"
DOMAIN="b5o2p.com"

clean() {
    rm -r "${OUTPUT_DIR}/$@.${DOMAIN}/data"
}

clean org1
clean org2
clean org3
clean org4
clean org5