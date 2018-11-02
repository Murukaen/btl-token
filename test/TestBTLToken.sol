pragma solidity ^0.4.22;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BTLToken.sol";

contract TestBTLToken {
    uint public initialBalance = 10 ether;
    
    function testContractInitialProps() public {
        BTLToken token = BTLToken(DeployedAddresses.BTLToken());
        Assert.equal(token.name(), "BTL Token", "Contract name should match");     
        Assert.equal(token.symbol(), "BTL", "Contract symbol should match");
        Assert.equal(token.decimals(), uint(8), "Contract decimal number should match");
        Assert.equal(token.totalSupply(), 21000000 * 10 ** 8, "Contract total supply should match");
        Assert.equal(token.tokensMinted(), 0, "Contract should start with 0 tokens minted");
        Assert.equal(token.rewardEra(), 0, "Contract should start with 0 for reward era");
        Assert.equal(token.rewardEra(), 0, "Contract should start with 0 for reward era");
    }

    function testInitialBalance() public {
        BTLToken token = BTLToken(DeployedAddresses.BTLToken());
        Assert.equal(token.balanceOf(msg.sender), 0, "Owner should have 0 BTL initially");
    }
}
