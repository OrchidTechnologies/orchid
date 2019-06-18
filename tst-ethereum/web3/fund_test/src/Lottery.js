import web3 from './web3';

const Lottery_addr  = "0x5fb59295bc3fa635b1baf82f80293ca419adc331";

const Lottery_abi = [{"constant":false,"inputs":[{"name":"secret","type":"uint256"},{"name":"hash","type":"bytes32"},{"name":"target","type":"address"},{"name":"nonce","type":"uint256"},{"name":"until","type":"uint256"},{"name":"ratio","type":"uint256"},{"name":"amount","type":"uint64"},{"name":"v","type":"uint8"},{"name":"r","type":"bytes32"},{"name":"s","type":"bytes32"},{"name":"old","type":"bytes32[]"}],"name":"grab","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"target","type":"address"}],"name":"take","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"warn","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"signer","type":"address"},{"name":"amount","type":"uint64"},{"name":"total","type":"uint64"}],"name":"fund","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"name":"orchid","type":"address"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"name":"signer","type":"address"},{"indexed":false,"name":"amount","type":"uint64"},{"indexed":false,"name":"escrow","type":"uint64"},{"indexed":false,"name":"unlock","type":"uint256"}],"name":"Update","type":"event"}];


export default new web3.eth.Contract(Lottery_abi,  Lottery_addr);
