const Web3 = require('web3');
const BigInt = require("big-integer");

/// Capture console and error output to an element with id `logId` in the page.
function captureLogsTo(logId) {
    window.orgLog = console.log;
    window.logText = "";
    console.log = function (...args) {
        // args = args.map(arg => {
        //     if (typeof arg == "string" || typeof arg == "number") {
        //         return arg
        //     } else {
        //         return JSON.stringify(arg)
        //     }
        // });
        window.logText += "<span>Log: " + args.join(" ") + "</span><br/>";
        let log = document.getElementById(logId);
        if (log) {
            log.innerHTML = logText;
        }
        orgLog.apply(console, arguments);
    };
    // Capture errors
    window.onerror = function (message, source, lineno, colno, error) {
        if (error) message = error.stack;
        console.log('Error: ' + message + ": " + error);
        console.log('Error json: ', JSON.stringify(error));
    };
    window.onload = function () {
        console.log("Loaded.");
    };
}

window.captureLogsTo = captureLogsTo;

/// Init the Web3 environment and the Orchid contracts
function init_ethereum() {
    return new Promise(function (resolve, reject) {
        window.addEventListener('load', async () => {
            // Modern DAPP browsers.
            if (window.ethereum) {
                console.log("Modern dapp browser.");
                window.web3 = new Web3(ethereum);
                try {
                    await ethereum.enable();
                } catch (error) {
                    console.log("User denied account access...");
                }
            }
            // Legacy DAPP browsers.
            else if (window.web3) {
                window.web3 = new Web3(web3.currentProvider);
            }
            // Non-dapp browsers...
            else {
                console.log('Non-Ethereum browser.');
                reject();
            }

            try {
                Orchid.token = new window.web3.eth.Contract(Orchid.token_abi, Orchid.token_addr);
                Orchid.lottery = new window.web3.eth.Contract(Orchid.lottery_abi, Orchid.lottery_addr);
            } catch (err) {
                console.log("Error constructing contracts");
            }

            resolve();
        });
    });
}

window.init_ethereum = init_ethereum;

class URLParams {
    constructor() {
        this.potAddress = "";
        this.amount = 0;
    }
}

function getURLParams() {
    let result = new URLParams();
    let params = new URLSearchParams(document.location.search);
    result.potAddress = params.get("pot");
    result.amount = params.get("amount");
    return result;
}

window.getURLParams = getURLParams;

class Account {
    constructor() {
        this.address = "";
        this.ethBalance = ""; // wei as string
        this.oxtBalance = ""; // OXT-wei as string
    }
}

/// Get the user's ETH wallet balance and OXT-wei token balance (1e18 parts OXT).
async function getAccount() {
    const accounts = await web3.eth.getAccounts();
    const account = new Account();
    account.address = accounts[0];
    try {
        account.ethBalance = (await web3.eth.getBalance(accounts[0])).toString();
    } catch (err) {
        console.log("Error getting eth balance", err);
    }
    try {
        account.oxtBalance = (await Orchid.token.methods.balanceOf(accounts[0]).call()).toString();
    } catch (err) {
        console.log("Error getting oxt balance", err);
    }
    return account;
}

window.getAccount = getAccount;

function isAddress(str) {
    return web3.utils.isAddress(str);
}

window.isAddress = isAddress;

/// Transfer the amount in OXT-wei string value from the user to the specified lottery pot address.
async function fundPot(addr, amount/*:String*/, escrow/*:String*/) {
    console.log("Fund address: ", addr, " amount: ", amount, " escrow: ", escrow);
    const accounts = await web3.eth.getAccounts();

    // Lottery funding amount
    const amount_value = BigInt(amount);
    const escrow_value = BigInt(escrow);
    const total = amount_value + escrow_value;

    // Gas price
    //const gwei = 1e9;
    //const gasPrice = 20;
    //console.log("Setting gas price (gwei): ", gasPrice);

    return new Promise(function (resolve, reject) {

        function doApproveTx(onComplete) {
            //Orchid.token.methods.approve(Orchid.lottery_addr, total.toString())
            //.estimateGas({from: accounts[0]})
            //.then((gas) => {
            //console.log("Approval gas estimate: ", gas);
            //});

            Orchid.token.methods.approve(Orchid.lottery_addr, total.toString()).send({
                from: accounts[0],
                gas: Orchid.token_approval_max_gas,
                //gasPrice: gasPrice * gwei
            })
                .on("transactionHash", (hash) => {
                    console.log("Approval hash: ", hash);
                    onComplete()
                })
                .on('confirmation', (confirmationNumber, receipt) => {
                    console.log("Approval confirmation ", confirmationNumber, JSON.stringify(receipt));
                })
                .on('error', (err) => {
                    console.log("Approval error: ", JSON.stringify(err));
                    // If there is an error in the approval assume Funding will fail.
                    reject(err);
                });
        }

        function doFundTx() {
            //Orchid.lottery.methods.fund(addr, amount_value.toString(), total.toString())
            //.estimateGas({from: accounts[0]})
            //.then((gas) => {
            //console.log("Funding gas estimate: ", gas);
            //});

            Orchid.lottery.methods.fund(addr, amount_value.toString(), total.toString()).send({
                from: accounts[0],
                gas: Orchid.lottery_fund_max_gas,
                //gasPrice: gasPrice * gwei
            })
                .on("transactionHash", (hash) => {
                    console.log("Fund hash: ", hash);
                })
                .on('confirmation', (confirmationNumber, receipt) => {
                    console.log("Fund confirmation", confirmationNumber, JSON.stringify(receipt));
                    // Wait for one confirmation on the funding tx.
                    window.receipt = receipt;
                    const hash = receipt['transactionHash'];
                    resolve(hash);
                })
                .on('error', (err) => {
                    console.log("Fund error: ", JSON.stringify(err));
                    reject(err);
                });
        }

        try {
            doApproveTx(doFundTx);
        } catch (err) {
            console.log("error:", JSON.stringify(err));
            reject("error: " + err);
        }
    });
}

window.fundPot = fundPot;


/// Get the lottery pot balance and escrow amount for the specified address.
/// Returned as an array of strings: [balance, escrow]
async function getPotInfo(addr) {
    const accounts = await web3.eth.getAccounts();
    let result = await Orchid.lottery.methods.balance(addr).call({from: accounts[0],});
    if (result == null || result._length < 2) {
        return null;
    }
    const balance = result[0]; // web3.util.BN
    const escrow = result[1]; // web3.util.BN
    console.log("Get pot balance: ", balance.toString(), "escrow: ", escrow.toString());
    return [balance.toString(), escrow.toString()];
}

window.getPotInfo = getPotInfo;

