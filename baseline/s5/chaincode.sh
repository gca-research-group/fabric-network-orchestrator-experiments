#!/usr/bin/env bash
set -euo pipefail

# 1. Run go mod tidy for all chaincodes
docker exec tools.org1.b-s5.com sh -c "cd /chaincodes/asset && go mod tidy"
docker exec tools.org1.b-s5.com sh -c "cd /chaincodes/product && go mod tidy"
docker exec tools.org1.b-s5.com sh -c "cd /chaincodes/private-agreement && go mod tidy"

# 2. Package all chaincodes (Asset v1.0, Product v1.0, PrivateAgreement v2.0)
docker exec tools.org1.b-s5.com peer lifecycle chaincode package /chaincodes/asset/Asset_1.0.tar.gz --path /chaincodes/asset --lang golang --label Asset_1.0
docker exec tools.org1.b-s5.com peer lifecycle chaincode package /chaincodes/product/Product_1.0.tar.gz --path /chaincodes/product --lang golang --label Product_1.0
docker exec tools.org1.b-s5.com peer lifecycle chaincode package /chaincodes/private-agreement/PrivateAgreement_2.0.tar.gz --path /chaincodes/private-agreement --lang golang --label PrivateAgreement_2.0

# 3. Install all chaincodes on Org1, Org2, and Org3 peers
docker exec tools.org1.b-s5.com peer lifecycle chaincode install /chaincodes/asset/Asset_1.0.tar.gz
docker exec tools.org1.b-s5.com peer lifecycle chaincode install /chaincodes/product/Product_1.0.tar.gz
docker exec tools.org1.b-s5.com peer lifecycle chaincode install /chaincodes/private-agreement/PrivateAgreement_2.0.tar.gz

docker exec tools.org2.b-s5.com peer lifecycle chaincode install /chaincodes/asset/Asset_1.0.tar.gz
docker exec tools.org2.b-s5.com peer lifecycle chaincode install /chaincodes/product/Product_1.0.tar.gz
docker exec tools.org2.b-s5.com peer lifecycle chaincode install /chaincodes/private-agreement/PrivateAgreement_2.0.tar.gz

docker exec tools.org3.b-s5.com peer lifecycle chaincode install /chaincodes/asset/Asset_1.0.tar.gz
docker exec tools.org3.b-s5.com peer lifecycle chaincode install /chaincodes/product/Product_1.0.tar.gz
docker exec tools.org3.b-s5.com peer lifecycle chaincode install /chaincodes/private-agreement/PrivateAgreement_2.0.tar.gz

# 4. Dynamically capture the generated Package IDs
ASSET_ID=$(docker exec tools.org1.b-s5.com peer lifecycle chaincode calculatepackageid /chaincodes/asset/Asset_1.0.tar.gz)
PRODUCT_ID=$(docker exec tools.org1.b-s5.com peer lifecycle chaincode calculatepackageid /chaincodes/product/Product_1.0.tar.gz)
PRIVATE_ID=$(docker exec tools.org1.b-s5.com peer lifecycle chaincode calculatepackageid /chaincodes/private-agreement/PrivateAgreement_2.0.tar.gz)

# 5. Approve chaincodes for Org1, Org2, and Org3
docker exec tools.org1.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name Asset --version 1.0 --sequence 1 --package-id "$ASSET_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt
docker exec tools.org2.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name Asset --version 1.0 --sequence 1 --package-id "$ASSET_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt
docker exec tools.org3.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name Asset --version 1.0 --sequence 1 --package-id "$ASSET_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt

docker exec tools.org1.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name Product --version 1.0 --sequence 1 --package-id "$PRODUCT_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --signature-policy "AND('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')"
docker exec tools.org2.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name Product --version 1.0 --sequence 1 --package-id "$PRODUCT_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --signature-policy "AND('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')"
docker exec tools.org3.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name Product --version 1.0 --sequence 1 --package-id "$PRODUCT_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --signature-policy "AND('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')"

docker exec tools.org1.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name PrivateAgreement --version 2.0 --sequence 1 --package-id "$PRIVATE_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --channel-config-policy Channel/Application/Endorsement --collections-config /chaincodes/private-agreement/collections_config.json
docker exec tools.org2.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name PrivateAgreement --version 2.0 --sequence 1 --package-id "$PRIVATE_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --channel-config-policy Channel/Application/Endorsement --collections-config /chaincodes/private-agreement/collections_config.json
docker exec tools.org3.b-s5.com peer lifecycle chaincode approveformyorg --channelID defaultchannel --name PrivateAgreement --version 2.0 --sequence 1 --package-id "$PRIVATE_ID" --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --channel-config-policy Channel/Application/Endorsement --collections-config /chaincodes/private-agreement/collections_config.json

# 6. Commit the chaincode definitions to the channel
docker exec tools.org1.b-s5.com peer lifecycle chaincode commit --channelID defaultchannel --name Asset --version 1.0 --sequence 1 --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --peerAddresses peer0.org1.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/peerOrganizations/org1.b-s5.com/peers/peer0.org1.b-s5.com/tls/ca.crt --peerAddresses peer0.org2.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org2.b-s5.com/peerOrganizations/org2.b-s5.com/peers/peer0.org2.b-s5.com/tls/ca.crt --peerAddresses peer0.org3.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org3.b-s5.com/peerOrganizations/org3.b-s5.com/peers/peer0.org3.b-s5.com/tls/ca.crt

docker exec tools.org1.b-s5.com peer lifecycle chaincode commit --channelID defaultchannel --name Product --version 1.0 --sequence 1 --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --signature-policy "AND('Org1MSP.peer', 'Org2MSP.peer', 'Org3MSP.peer')" --peerAddresses peer0.org1.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/peerOrganizations/org1.b-s5.com/peers/peer0.org1.b-s5.com/tls/ca.crt --peerAddresses peer0.org2.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org2.b-s5.com/peerOrganizations/org2.b-s5.com/peers/peer0.org2.b-s5.com/tls/ca.crt --peerAddresses peer0.org3.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org3.b-s5.com/peerOrganizations/org3.b-s5.com/peers/peer0.org3.b-s5.com/tls/ca.crt

docker exec tools.org1.b-s5.com peer lifecycle chaincode commit --channelID defaultchannel --name PrivateAgreement --version 2.0 --sequence 1 --orderer orderer.org1.b-s5.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/ordererOrganizations/org1.b-s5.com/orderers/orderer.org1.b-s5.com/tls/ca.crt --channel-config-policy Channel/Application/Endorsement --collections-config /chaincodes/private-agreement/collections_config.json --peerAddresses peer0.org1.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org1.b-s5.com/peerOrganizations/org1.b-s5.com/peers/peer0.org1.b-s5.com/tls/ca.crt --peerAddresses peer0.org2.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org2.b-s5.com/peerOrganizations/org2.b-s5.com/peers/peer0.org2.b-s5.com/tls/ca.crt --peerAddresses peer0.org3.b-s5.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/org3.b-s5.com/peerOrganizations/org3.b-s5.com/peers/peer0.org3.b-s5.com/tls/ca.crt
