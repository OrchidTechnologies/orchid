pragma solidity ^0.5.7;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";

contract OrchidToken is ERC20, ERC20Detailed {
    constructor()
        ERC20Detailed("Test", "TST", 18)
    public {
    }
}
