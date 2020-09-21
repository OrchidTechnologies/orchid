/* Orchid - WebRTC P2P VPN Market (on Ethereum)
 * Copyright (C) 2017-2019  The Orchid Authors
*/

/* The MIT License (MIT) {{{ */
/*
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:

 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
**/
/* }}} */


pragma solidity 0.5.12;

import "../openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "../openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

#if ORC_677
contract ERC677 is ERC20 {
    function transferAndCall(address recipient, uint amount, bytes calldata data) external returns (bool success);
    event Transfer(address indexed sender, address indexed recipient, uint amount, bytes data);
}

contract ERC677Receiver {
    function onTokenTransfer(address sender, uint amount, bytes calldata data) external;
}

contract OrchidToken677 is ERC677, ERC20Detailed {
#else
contract OrchidToken677 is ERC20, ERC20Detailed {
#endif
    constructor()
        ERC20Detailed("Orchid", "OXT", 18)
    public {
        _mint(msg.sender, 10**9 * 10**uint256(decimals()));
    }

#if ORC_677
    function transferAndCall(address recipient, uint amount, bytes calldata data) external returns (bool success) {
        super.transfer(recipient, amount);
        emit Transfer(msg.sender, recipient, amount, data);
        ERC677Receiver(recipient).onTokenTransfer(msg.sender, amount, data);
        return true;
    }
#endif
}
