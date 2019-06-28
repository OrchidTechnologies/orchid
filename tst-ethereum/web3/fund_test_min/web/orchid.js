const Web3 = require('web3');

/// Capture console and error output to an element named "log" in the page.
function captureLogsTo(logId) {
    window.orgLog = console.log;
    window.logText = "";
    console.log = function (...args) {
        // window.logText += "<span style='font-size: 18px'>Logger: " + args.join(" ") + "</span><br/>";
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
    };
    window.onload = function () {
        console.log("Loaded.");
    };
}

window.captureLogsTo = captureLogsTo;

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

class Account {
    constructor() {
        this.address = "";
        this.ethBalance = 0;
        this.oxtBalance = 0;
    }
}

async function getAccount() {
    const accounts = await web3.eth.getAccounts();
    const account = new Account();
    account.address = accounts[0];
    try {
        account.ethBalance = await web3.eth.getBalance(accounts[0]);
    } catch (err) {
        console.log("Error getting eth balance");
    }
    try {
        account.oxtBalance = await Orchid.token.methods.balanceOf(accounts[0]).call();
    } catch (err) {
        console.log("Error getting oxt balance");
    }
    return account;
}

window.getAccount = getAccount;

function isAddress(str) {
    return web3.utils.isAddress(str);
}

window.isAddress = isAddress;

async function fundPot(addr, amount) {
    const accounts = await web3.eth.getAccounts();

    // Lottery funding amount
    const value = amount;
    const escrow = 0;
    const total = value + escrow;

    // Gas price
    const gwei = 1e9;
    const gasPrice = 20;
    console.log("Setting gas price (gwei): ", gasPrice);

    return new Promise(function (resolve, reject) {
        try {
            Orchid.token.methods.approve(Orchid.lottery_addr, total)
                .estimateGas({from: accounts[0]})
                .then((gas) => {
                    console.log("Approval gas estimate: ", gas);
                });

            Orchid.token.methods.approve(Orchid.lottery_addr, total).send({
                from: accounts[0],
                gas: 50000,
                gasPrice: gasPrice * gwei
            })
                .on("transactionHash", (hash) => {
                    console.log("Approval hash: ", hash);
                })
                .on('confirmation', (confirmationNumber, receipt) => {
                    console.log("Approval confirmation: ", confirmationNumber, receipt);
                })
                .on('error', (err) => {
                    console.log("Approval error: ", err);
                    reject(err);
                });

            Orchid.lottery.methods.fund(addr, value, total)
                .estimateGas({from: accounts[0]})
                .then((gas) => {
                    console.log("Funding gas estimate: ", gas);
                });

            Orchid.lottery.methods.fund(addr, value, total).send({
                from: accounts[0],
                gas: 100000,
                gasPrice: gasPrice * gwei
            })
                .on("transactionHash", (hash) => {
                    console.log("Fund hash: ", hash);
                    resolve(hash);
                })
                .on('confirmation', (confirmationNumber, receipt) => {
                    console.log("Fund confirmation: ", confirmationNumber, receipt);
                })
                .on('error', (err) => {
                    console.log("Fund error: ", err);
                    reject(err);
                });
        } catch (err) {
            console.log("error:", err);
            reject("error: " + err);
        }
    });
}

window.fundPot = fundPot;


