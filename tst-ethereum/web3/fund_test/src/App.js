import React, { Component } from 'react';
import logo from './logo.svg';
import web3 from './web3';
import Token_obj from './Token';
import Lottery_obj from './Lottery';
import './App.css';


const one_eth   = 1000000000000000000;
//const one_eth_s = "1000000000000000000";

// const balance = await web3.eth.getBalance(auction.options.address);

class App extends Component {

    state = {
        eth_balance    : 0,
        oxt_balance    : 0,
        sent           : 0,
        
    };
  
  
    async componentDidMount() {


        if (window.ethereum) {
            //window.web3 = new Web3(ethereum);
            // Request account access if needed
            await window.ethereum.enable();
        }
    
        web3.eth.getBlockNumber().then(console.log);
              
        const accounts = await web3.eth.getAccounts();
        console.log(accounts);
        
        if (accounts[0]) {}
        else { throw new Error('Your MetaMask is locked. Unlock it to continue.'); }
        
        //const eth_balance_ = await web3.eth.getBalance("0xa045423feed61fD3E5c4324f03EB0aD2f66B32A4");   
        const eth_balance_ = await web3.eth.getBalance(accounts[0]);   

        console.log(Token_obj.options.address);
        console.log(Token_obj.address);

	    //var ten    = web3.utils.toWei('10','ether'); // OCT & ETH have same precision
	    var twenty = web3.utils.toWei('20','ether'); // OCT & ETH have same precision
        

        const oxt_balance_ = await Token_obj.methods.balanceOf(accounts[0]).call();   
        

        this.setState({eth_balance : eth_balance_, oxt_balance : oxt_balance_});


        await Token_obj.methods.approve(Lottery_obj.address, twenty ).send( { from: accounts[0] } ); 

        //await Lottery_obj.methods.fund(accounts[0], ten, ten ).send( { from: accounts[0] } ); 
        
    };  


    async send_fund() {
        if (this.state.oxt_balance > 0) {
            const accounts = await web3.eth.getAccounts();
	        var ten    = web3.utils.toWei('10','ether'); // OCT & ETH have same precision
            await Lottery_obj.methods.fund(accounts[0], ten, ten ).send( { from: accounts[0] } ); 
        }
    }

    render() {
        this.send_fund();
        
      return (
        <div className="App">
          <header className="App-header">
            <img src={logo} className="App-logo" alt="logo" />
            <p>
            eth balance: {(this.state.eth_balance) / (one_eth)}
            </p>
            <p>
            oxt balance: {(this.state.oxt_balance) / (one_eth)}
            </p>
            <p>
              Doing blockchain stuff!
            </p>
          </header>
        </div>
      );
    }

};



export default App;


