pragma solidity 0.5.12;

contract DummyToken {
    mapping(address => uint256) public balanceOf;

    constructor() public {
        balanceOf[msg.sender] = 10**27;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(amount <= balanceOf[from]);

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        return true;
    }
}
