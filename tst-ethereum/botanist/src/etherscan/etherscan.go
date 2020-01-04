package etherscan

import (
	"fmt"
	"strings"
	"io/ioutil"
	"encoding/json"
	"net/http"
	"strconv"
	"math/big"
	"../ethereum"
	log "github.com/sirupsen/logrus"
)

const apiBaseUrl = "https://api.etherscan.io/api"

func apiCallBase(key string, module string, action string, argstr string) (error, []byte) {
	qstr := fmt.Sprintf("%s?module=%s&action=%s&sort-asc&%s&apikey=%s", apiBaseUrl, module, action, argstr, key)
	resp, err := http.Get(qstr)
	log.Debug("Etherscan query:" + qstr)

	if err != nil {
		log.Error(err)
		return err, nil
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)

	if err != nil {
		log.Error(err)
		return err, nil
	}
	return nil, body
}

func apiCallPlural(key string, module string, action string, argstr string) (error, []map[string]string) {
	err, body := apiCallBase(key, module, action, argstr)
	if err != nil {
		return err, nil
	}

	type Response struct {
		Status  string
		Message string
		Result  []map[string]string
	}

	var r Response
	err = json.Unmarshal(body, &r)

	if err != nil {
		log.Error(err)
		return err, nil
	}
	return nil, r.Result
}

func apiCallSingular(key string, module string, action string, argstr string) (error, map[string]string) {
	err, body := apiCallBase(key, module, action, argstr)
	if err != nil {
		return err, nil
	}

	type Response struct {
		Status  string
		Message string
		Result  map[string]string
	}

	var r Response
	err = json.Unmarshal(body, &r)

	if err != nil {
		log.Error(err)
		return err, nil
	}
	return nil, r.Result
}

type EtherscanTxn struct {
	Hash     string
	From     string
	To       string
	Amount   *big.Int
	Currency ethereum.DigitalCurrency
	Function string
}

func AccountTransactions(key string, addr string, start string, end string, contract ethereum.Contract) (error, []EtherscanTxn) {
	log.Trace("Etherscan key" + key)

	type Transaction struct {
		BlockNumber       string
		Timestamp         string
		Hash              string
		Nonce             string
		BlockHash         string
		From              string
		ContractAddress   string
		To                string
		Value             string
		TokenName         string
		TokenSymbol       string
		TokenDecimal      string
		TransactionIndex  string
		Gas               string
		GasPrice          string
		GasUsed           string
		CumulativeGasUsed string
		Input             string
		Confirmations     string
	}

	addrStr := fmt.Sprintf("address=%s", addr)
	startStr := fmt.Sprintf("startblock=%s", start)
	endStr := fmt.Sprintf("endblock=%s", end)
	argstr := strings.Join([]string{addrStr, startStr, endStr}, "&")
	
	err, result := apiCallPlural(key, "account", "tokentx", argstr)
	if err != nil {
		log.Error(err)
		return err, nil
	}

	out := make([]EtherscanTxn, 0)
	for _, t := range result {
		amt := new(big.Int)
		amt.SetString(t["value"], 10)

		d, err := strconv.Atoi(t["tokenDecimal"])
		if err != nil {
			log.Warn(err)
			continue
		}

		cur := ethereum.DigitalCurrency{t["tokenSymbol"], d}
		
		err, txres := apiCallSingular(key, "proxy", "eth_getTransactionByHash", fmt.Sprintf("txhash=%s", t["hash"]))
		fstr := "00000000"
		if err == nil {
			fstr = txres["input"][2:10]
			if contract.Functions[fstr] != "" {
				fstr = contract.Functions[fstr]
			}
		}
		
		out = append(out, EtherscanTxn{t["hash"], t["from"], t["to"], amt, cur, fstr})
	}
	return nil, out
}

