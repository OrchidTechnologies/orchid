package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
)

var rootCmd = &cobra.Command{
	Use:   "botanist",
	Short: "Botanist tobulates metrics for monitoring Orchid",
	Long:  ``,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
	},
	TraverseChildren: true,
}

func init() {
	rootCmd.PersistentFlags().StringVarP(&ApiKey, "apikey", "k", "doesntseemtomatter", "Etherscan API key")
	rootCmd.PersistentFlags().StringVarP(&LottoAddr, "lotto", "l", "0xb02396f06cc894834b7934ecf8c8e5ab5c1d12f1", "Lottery contract address")
	rootCmd.PersistentFlags().StringVarP(&StartBlock, "start", "s", "0", "Starting block number")
	rootCmd.PersistentFlags().StringVarP(&EndBlock, "end", "e", "999999999", "Ending block number")
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

var StartBlock, EndBlock, ApiKey, LottoAddr string
