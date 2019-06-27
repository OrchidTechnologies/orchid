
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

async function getAccounts() {
    const accounts = await web3.eth.getAccounts();
    console.log("accounts: ", accounts);
    return accounts;
}

function isAddress(str) {
    return web3.utils.isAddress(str);
}

async function fundPot(addr, amount) {
    const accounts = await web3.eth.getAccounts();

    // Convert the amount to/from wei
    const value = amount;
    const escrow = 0;
    const total = value + escrow;

    try {
        let result = await Orchid.token.methods.approve(Orchid.lottery_addr, total).send({from: accounts[0]});
        console.log("Approval result: ", JSON.stringify(result));
        result = await Orchid.lottery.methods.fund(addr, value, total).send({from: accounts[0]});
        let jsonResult = JSON.stringify(result);
        console.log("Fund result: ", jsonResult);
        return jsonResult;
    } catch (err) {
        console.log("error:", err);
        throw new Error("Error in transaction.");
    }
}


