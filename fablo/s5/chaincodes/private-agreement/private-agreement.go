package main

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

type SmartContract struct {
	contractapi.Contract
}

type PrivateAgreement struct {
	ID        string `json:"id"`
	PartyA    string `json:"partyA"`
	PartyB    string `json:"partyB"`
	SecretKey string `json:"secretKey"`
}

func (s *SmartContract) CreatePrivateAgreement(
	ctx contractapi.TransactionContextInterface,
	id string) error {

	transientData, err := ctx.GetStub().GetTransient()
	if err != nil {
		return err
	}

	dataJSON := transientData["agreement"]
	if dataJSON == nil {
		return fmt.Errorf("agreement not found in transient map")
	}

	return ctx.GetStub().PutPrivateData(
		"collectionAgreements",
		id,
		dataJSON,
	)
}

func (s *SmartContract) ReadPrivateAgreement(
	ctx contractapi.TransactionContextInterface,
	id string,
) (*PrivateAgreement, error) {

	data, err := ctx.GetStub().GetPrivateData(
		"collectionAgreements",
		id,
	)
	if err != nil {
		return nil, err
	}

	if data == nil {
		return nil, fmt.Errorf("agreement not found")
	}

	var agreement PrivateAgreement
	err = json.Unmarshal(data, &agreement)
	if err != nil {
		return nil, err
	}

	return &agreement, nil
}

func (s *SmartContract) ReadAllPrivateAgreements(
	ctx contractapi.TransactionContextInterface,
) ([]*PrivateAgreement, error) {

	resultsIterator, err := ctx.GetStub().GetPrivateDataByRange(
		"collectionAgreements",
		"",
		"",
	)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var agreements []*PrivateAgreement

	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}

		var agreement PrivateAgreement

		err = json.Unmarshal(queryResponse.Value, &agreement)
		if err != nil {
			return nil, err
		}

		agreements = append(agreements, &agreement)
	}

	return agreements, nil
}

func main() {
	chaincode, err := contractapi.NewChaincode(new(SmartContract))
	if err != nil {
		log.Panic(err)
	}

	if err := chaincode.Start(); err != nil {
		log.Panic(err)
	}
}
