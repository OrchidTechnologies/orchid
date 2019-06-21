function init_ethereum() {
    window.addEventListener('load', async () => {
        // Modern DAPP browsers.
        if (window.ethereum) {
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
            console.log('Non-Ethereum browser. Please install MetaMask.');
        }

        Orchid.token = new window.web3.eth.Contract(Orchid.token_abi, Orchid.token_addr);
        Orchid.lottery = new window.web3.eth.Contract(Orchid.lottery_abi, Orchid.lottery_addr);
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
    account.ethBalance = await web3.eth.getBalance(accounts[0]);
    account.oxtBalance = await Orchid.token.methods.balanceOf(accounts[0]).call();
    return account;
}

async function getAccounts() {
    const accounts = await web3.eth.getAccounts();
    console.log("accounts: ", accounts);
    return accounts;
}

function isAddress(str) {
    const result = web3.utils.isAddress(str);
    console.log("isAddress: " + str + ", " + result);
    return result;
}

async function fundPot(addr, amount) {
    const accounts = await web3.eth.getAccounts();
    
    // Convert the amount to/from wei
    const value = amount;
    const escrow = 0;
    const total = value + escrow;

    try {
        await Orchid.token.methods.approve(Orchid.lottery_addr, total).send({from: accounts[0]});
        console.log("approved");
        const result = await Orchid.lottery.methods.fund(addr, value, total).send({from: accounts[0]});
        console.log("fund: result = ", result);
        return JSON.stringify(result);
    } catch (err) {
        console.log("error:", err);
        return "Error in transaction.";
    }
}

async function debug() {
    // const accounts = await web3.eth.getAccounts();
    // const oxtBalance = await Orchid.token.methods.balanceOf(accounts[0]).call();
    // console.log("balance: ", oxtBalance);
    // const twenty = web3.utils.fromWei('20','ether');
    // console.log("twenty  ", twenty);
    // await Orchid.lottery.methods.warn().send({from: accounts[0]});
    // console.log("lot = ", Orchid.lottery);
    // console.log("address1 = ", Orchid.lottery_addr);
    // await Orchid.token.methods.approve( Orchid.lottery_addr, '20').send({from: accounts[0]});
}

