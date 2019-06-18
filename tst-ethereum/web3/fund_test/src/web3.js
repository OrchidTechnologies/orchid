import Web3 from 'web3';

const web3 = new Web3(window.web3.currentProvider);
console.log(web3.eth.accounts);

export default web3;
