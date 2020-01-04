package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/OrchidTechnologies/orchid/tst-ethereum/botanist/orchid"
	"math"
	"strconv"
)



var talliesCmd = &cobra.Command{
  Use:   "tallies",
  Short: "Print tallies of useful metrics",
  Long: ``,
  Run: func(cmd *cobra.Command, args []string) {
	grabsize, _ := strconv.Atoi(MinFaceValue)
	err, lot := orchid.NewLotteryFromEtherscan(ApiKey, LottoAddr, StartBlock, EndBlock)
	if err != nil {
		fmt.Println(err)
		return
	}
	lot.Tallies(int64(math.Pow10(grabsize)))
  },
}

func init() {
	rootCmd.AddCommand(talliesCmd)
	talliesCmd.PersistentFlags().StringVarP(&MinFaceValue, "minface", "c", "16", "Only print payments of face value > 10^x keiki")
}

var MinFaceValue string