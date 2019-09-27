const $ = require('jquery');
require('jquery-ui-browserify');
const BigInt = require("big-integer");
const rxjs = require("rxjs");
const rxjsops = require("rxjs/operators");

// Form validation
const validPotAddress = new rxjs.BehaviorSubject(null);
const validPotAmount = new rxjs.BehaviorSubject(null);
const validPotEscrow = new rxjs.BehaviorSubject(null);
const validForm = rxjs.combineLatest([validPotAddress, validPotAmount, validPotEscrow])
    .pipe(rxjsops.map(val => {
        const [address, amount, escrow] = val;
        return address != null && amount != null && escrow != null;
    }));

async function init_app() {
    window.initialized = false;

    // Allow init ethereum to create the web3 context for validation
    await init_ethereum();
    await showWalletBalance();

    $(document).ready(async function () {
        init_ui();
        init_listeners();

        // e.g. http://192.168.1.2:8123/web/index.html?pot=0x405BC10E04e3f487E9925ad5815E4406D78B769e&amount=2
        let params = new URLSearchParams(document.location.search);

        // Accept initial params from the URL or browser auto-populated
        await setPotAddress(params.get("pot") || $('#pot').val());
        await setAmount(params.get("amount") || $('#amount').val());
        await setEscrow(params.get("escrow") || $('#escrow').val());

        // Show the page after initialization complete
        document.body.removeAttribute('hidden');
        window.initialized = true;
    });
}

window.init_app = init_app;

function init_ui() {
    $("#accordion").accordion({
        heightStyle: "content"
    });
}

function init_listeners() {
    rxjs.fromEvent($('#pot'), 'input')
        .subscribe((event) => setPotAddress(event.target.value));
    rxjs.fromEvent($('#amount'), 'input')
        .subscribe((event) => setAmount(event.target.value));
    rxjs.fromEvent($('#escrow'), 'input')
        .subscribe((event) => setEscrow(event.target.value));

    $('#submit').attr('disabled', true);
    validForm.subscribe((valid) => {
        $('#submit').attr('disabled', !valid);
        updateOverview(valid);
    });
}

async function setAmount(value) {
    const valid = isNumeric(value);
    $('#amount-error').toggleClass('hidden', valid);
    if (valid) {
        $('#amount').val(value);
    }
    validPotAmount.next(valid ? value : null);
}

async function setEscrow(value) {
    const valid = isNumeric(value);
    $('#escrow-error').toggleClass('hidden', valid);
    if (valid) {
        $('#escrow').val(value);
    }
    validPotEscrow.next(valid ? value : null);
}

async function setPotAddress(address) {
    // Not strictly necessary but for consistency
    if (address != null && address !== "" && address !== "0" && !address.toLowerCase().startsWith("0x")) {
        address = "0x" + address;
    }
    const valid = isAddress(address);
    $('#pot-error').toggleClass('hidden', valid);
    if (valid) {
        $('#pot').val(address);
        await showPotBalance();
    }
    validPotAddress.next(valid ? address : null);
}

/// Return the value converted from wei, rounded to four decimals.
function fromWei(wei) {
    let val = web3.utils.fromWei(wei);
    return Math.round(val * 1e4) / 1e4;
}

async function showWalletBalance() {
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
}

async function showBalances() {
    await showWalletBalance();
    await showPotBalance();
}

async function showPotBalance() {
    let potAddress = $('#pot').val();
    let potInfo = await getPotInfo(potAddress);
    let potBalance = fromWei(potInfo[0]);
    $('#pot-balance').val(potBalance);
    let potEscrow = fromWei(potInfo[1]);
    $('#pot-escrow').val(potEscrow);
}

async function submitTx() {
    console.log("Submit...");
    let fundButton = $("#submit");
    fundButton.attr("disabled", true).css('opacity', '0.3');
    let spinner = $('#spinner');
    fundButton.toggle();
    spinner.slideDown();

    let amount = $('#amount').val();
    let escrow = $('#escrow').val();
    console.log("submit amounts: ", amount, escrow);

    try {
        // TODO: change to submit amount after validation
        const amountWei = BigInt(amount * 1e18).toString();
        const escrowWei = BigInt(escrow * 1e18).toString();
        console.log("fund amounts wei: ", amountWei, escrowWei);
        let potAddress = $('#pot').val();
        let tx = await fundPot(potAddress, amountWei, escrowWei);

        window.tx = tx; // debug
        console.log("Funded.");
        $("#result-text").text("Successful Transaction");
        try {
            $("#tx-id").text(JSON.parse(tx)['transactionHash']);
        } catch (err) {
        }
        await showBalances();
    } catch (err) {
        console.log("Fund pot error: ", err);
        $("#result-text").text("Transaction Failed");
    }
    spinner.slideUp();
    $("#results").slideDown();
}

window.submitTx = submitTx;

function updateOverview(valid)
{
    let accordion = $("#accordion");
    // let active = accordion.accordion( "option", "active" );
    let text;
    if (valid) {
        let amount, escrow;
        try {
            amount = parseFloat($('#amount').val());
            escrow = parseFloat($('#escrow').val());
        } catch (err) {
            console.log(err);
            return;
        }
        if (escrow > 0) {
            text =
                `This transaction will approve and transfer a total of <b>${amount + escrow} OXT</b>` +
                ` to your Orchid account.` +
                ` This includes a one time deposit of <b>${escrow} OXT</b> and a balance of <b>${amount} OXT</b>.`;
        } else {
            text =
                `This transaction will approve and transfer <b>${amount} OXT</b> to your Orchid account balance. `;
        }
    } else {
        text = "Please enter transaction details.";
    }
    $('#overview-text').get(0).innerHTML = text;

    // Set the initial view to the overview if we are in initialization time.
    if (!window.initialized) {
        accordion.accordion("option", "active", valid ? 0 : 1);
    }
}

function isNumeric(num) {
    if (num == null || num === "") {
        return false;
    }
    return !isNaN(num)
}

