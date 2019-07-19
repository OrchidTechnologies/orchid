const $ = require('jquery');
const BigInt = require("big-integer");

async function init_app() {
    await init_ethereum();
    // e.g. http://192.168.1.2:8123/web/index.html?pot=0x405BC10E04e3f487E9925ad5815E4406D78B769e&amount=2
    let params = new URLSearchParams(document.location.search);

    window.potAddress = params.get("pot");
    // Not strictly necessary but for consistency
    if (!window.potAddress.toLowerCase().startsWith("0x")) {
        window.potAddress = "0x"+window.potAddress;
    }
    if (!isAddress(potAddress)) {
        console.log("Pot address is invalid");
        $('#pot-error').removeClass('hidden');
    }
    $('#pot').val(potAddress);

    window.initial_amount = params.get("amount");
    if (initial_amount <= 0 || initial_amount > 10) {
        console.log("Fund amount is invalid");
        $('#amount-error').removeClass('hidden');
    }
    $('#amount').val(initial_amount);

    await showBalance();
}

window.init_app = init_app;

/// Return the value converted from wei, rounded to four decimals.
function fromWei(wei) {
    let val = web3.utils.fromWei(wei);
    return Math.round(val * 1e4)/1e4;
}

async function showBalance() {
    // Show the wallet balances
    let account = await getAccount();
    console.log("Funding from account: ", account.address);
    console.log("Balance: ", account.ethBalance);
    $('#from-account').val(account.address);
    let ethBalance = fromWei(account.ethBalance);
    $('#eth-balance').val(ethBalance);
    if (account.ethBalance <= 0) {
        $('#eth-balance-error').removeClass('hidden');
    }
    let oxtBalance = fromWei(account.oxtBalance);
    $('#oxt-balance').val(oxtBalance);
    if (account.oxtBalance <= 0) {
        $('#oxt-balance-error').removeClass('hidden');
    }
    // Show the pot balance
    let potBalance = fromWei(await getPotBalance(window.potAddress));
    $('#pot-balance').val(potBalance);
}
window.showBalance = showBalance;

async function submitTx() {
    console.log("Submit...");
    let fundButton = $("#fund-button");
    fundButton.attr("disabled", true).css('opacity', '0.3');
    let spinner = $('#spinner');
    fundButton.toggle();
    spinner.slideDown();
    let amount = $('#amount').val();
    console.log("submit amount = ", amount);

    try {
        // TODO: change to submit amount after validation
        const amountWei = BigInt(amount * 1e18).toString();
        console.log("fund amount wei = ", amountWei);
        let tx = await fundPot(potAddress, amountWei);

        window.tx=tx; // debug
        console.log("Funded.");
        $("#result-text").text("Successful Transaction");
        try {
            $("#tx-id").text(JSON.parse(tx)['transactionHash']);
        } catch (err) { }
        await showBalance();
    } catch (err) {
        console.log("Fund pot error: ", err);
        $("#result-text").text("Transaction Failed");
    }
    spinner.slideUp();
    $("#results").slideDown();
}
window.submitTx = submitTx;


