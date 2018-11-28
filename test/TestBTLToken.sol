pragma solidity ^0.4.22;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BTLToken.sol";

contract TestBTLToken {
    uint public initialBalance = 10 ether;
    uint coinsCount = 1000;
    uint decimals = 2;
    uint blocksCount = 100;
    uint blockTime = 600;
    
    function testContractInitialProps() public {
        BTLToken token = new BTLToken(coinsCount, uint8(decimals), blocksCount, blockTime, 0);
        Assert.equal(token.name(), "BTL Token", "Contract name should match");     
        Assert.equal(token.symbol(), "BTL", "Contract symbol should match");
        Assert.equal(uint(token.decimals()), decimals, "Contract decimal number should match");
        Assert.equal(token.totalSupply(), 0, "Contract total supply should match");
        Assert.equal(token.tokensMinted(), 0, "Contract should start with 0 tokens minted");
    }

    function testReward() public {
        BTLToken token = new BTLToken(coinsCount, uint8(decimals), blocksCount, blockTime, 0);
        Assert.equal(token.getBlockReward(1), 1503, "Reward for block 1 shld match");
        Assert.equal(token.getBlockReward(2), 1503, "Reward for block 2 shld match");
        Assert.equal(token.getBlockReward(3), 1502, "Reward for block 3 shld match");
        Assert.equal(token.getBlockReward(4), 1501, "Reward for block 4 shld match");
        Assert.equal(token.getBlockReward(5), 1499, "Reward for block 5 shld match");
        Assert.equal(token.getBlockReward(10), 1488, "Reward for block 10 shld match");
        Assert.equal(token.getBlockReward(25), 1410, "Reward for block 25 shld match");
        Assert.equal(token.getBlockReward(50), 1131, "Reward for block 50 shld match");
        Assert.equal(token.getBlockReward(75), 666, "Reward for block 75 shld match");
        Assert.equal(token.getBlockReward(90), 297, "Reward for block 90 shld match");
        Assert.equal(token.getBlockReward(95), 160, "Reward for block 95 shld match");
        Assert.equal(token.getBlockReward(100), 15, "Reward for block 100 shld match");
    }

    function testInitialBalance() public {
        BTLToken token = BTLToken(DeployedAddresses.BTLToken());
        Assert.equal(token.balanceOf(msg.sender), 0, "Owner should have 0 BTL initially");
    }
}
