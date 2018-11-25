pragma solidity ^0.4.22;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BTLToken.sol";

contract TestBTLToken {
    uint public initialBalance = 10 ether;
    uint coins_count = 1000;
    uint decimals = 2;
    uint blocks_count = 100; 
    
    function testContractInitialProps() public {
        BTLToken token = new BTLToken(coins_count, uint8(decimals), blocks_count, 0);
        Assert.equal(token.name(), "BTL Token", "Contract name should match");     
        Assert.equal(token.symbol(), "BTL", "Contract symbol should match");
        Assert.equal(uint(token.decimals()), decimals, "Contract decimal number should match");
        Assert.equal(token.totalSupply(), 0, "Contract total supply should match");
        Assert.equal(token.tokensMinted(), 0, "Contract should start with 0 tokens minted");
        Assert.equal(token.cummulativeEraMaxSupply(), coins_count * 10 ** decimals / 2, "Wrong cummulativeEraMaxSupply");
        // Assert.equal(token.rewardEra(), 0, "Contract should start with 0 for reward era");
    }

    function testInitialBalance() public {
        BTLToken token = BTLToken(DeployedAddresses.BTLToken());
        Assert.equal(token.balanceOf(msg.sender), 0, "Owner should have 0 BTL initially");
    }
}
