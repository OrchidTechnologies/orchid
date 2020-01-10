package main

import (
	"fmt"
	"math"
	"math/big"
	"time"
	"strings"
)

type Lottery struct {
	Accounts        []LotteryAccount
	Currency        DigitalCurrency
	Address         string
	Transactions    []LotteryTransaction
	LotteryContract Contract
}

type LotteryAccount struct {
	Funder       string
	Signer       string
	Balance      int
	Deposit      int
	Transactions []LotteryTransaction
}

type LotteryFunction int

const (
	In LotteryFunction = iota
	Out
)

type LotteryTransaction struct {
	Contract  Lottery
	Hash      string
	Timestamp time.Time
	From      string
	To        string
	Amount    *big.Int
	TxnType   string
}

func NewLotteryFromEtherscan(key string, addr string, start string, end string) (error, *Lottery) {
	out := Lottery{}
	out.Address = addr
	out.LotteryContract = Contract{"Lottery", addr,
		map[string]string{"66458bbd": "grab", "73fb4644": "push", "5f51b34e": "yank", "a6cbd6e3": "pull"}}

	err, txns := AccountTransactions(key, addr, start, end, out.LotteryContract)
	if err != nil {
		fmt.Println(err)
		return err, nil
	}

	ltxns := make([]LotteryTransaction, 0)
	for _, t := range txns {
		ltxns = append(ltxns, LotteryTransaction{out, t.Hash, t.Timestamp, t.From, t.To, t.Amount, t.Function})
		out.Currency = t.Currency
	}
	out.Transactions = ltxns
	return nil, &out
}

func (lotto *Lottery) Tallies(grabsize int64) string {
	intot := new(big.Int)
	outtot := new(big.Int)
	tottfr := new(big.Float)
	var funders []string
	var c, d int
	dec := int64(math.Pow10(lotto.Currency.Decimals))
	div := new(big.Int).SetInt64(dec)
	headstr, _ := Columnize(ColumnList{"Date": 29, "Txn Hash": 66, "Recipient": 42, "Face Value": 15})
	fmt.Println(headstr)
	for _, txn := range lotto.Transactions {
		if txn.TxnType == "grab" {
			if txn.Amount.Cmp(new(big.Int).SetInt64(grabsize)) != -1 {
				face := new(big.Float).Quo(new(big.Float).SetInt(txn.Amount), new(big.Float).SetInt(div))
				fmt.Println(txn.Timestamp, txn.Hash, txn.To, face)
				c++
				tottfr.Add(tottfr, face)
			}
			d++
		}
		if strings.EqualFold(txn.To, lotto.Address) {
			funders = AppendIfUnique(funders, txn.From)
			intot.Add(intot, txn.Amount)
		}
		if strings.EqualFold(txn.From, lotto.Address) {
			outtot.Add(outtot, txn.Amount)
		}
		//        fmt.Println(res.Timestamp, "\t", res.From, "\t", amount)
		//        fmt.Println(res)
	}
	threshold, _ := new(big.Float).Quo(new(big.Float).SetInt64(grabsize), new(big.Float).SetInt(div)).Float64()
	fl_tottfr, _ := tottfr.Float64()
	fmt.Printf("Total payments claimed by providers: %f OXT\n", fl_tottfr)
	fmt.Printf("%d grab() transactions of face value > %f %s out of %d total.\n", c, threshold, lotto.Currency.Ticker, d)

	in := new(big.Int).Div(intot, div)
	out := new(big.Int).Div(outtot, div)
	net := new(big.Int).Sub(in, out)
	fmt.Println("Total in: ", in, lotto.Currency.Ticker)
	fmt.Println("Total out: ", out, "OXT")
	fmt.Println("Net held in contract: ", net, lotto.Currency.Ticker)
	fmt.Println("Accounts: ", len(funders))
	return ""
}
