pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/BTLToken.sol";

contract TestBTLToken {
    function testInitialBalanceUsingDeployedContract() public {
        BTLToken token = BTLToken(DeployedAddresses.BTLToken());
        uint expected = 0;
        Assert.equal(token.balanceOf(msg.sender), expected, "Owner should have 0 BTL initially");
    }

    function testInitialBalanceWithNewMetaCoin() public {
        BTLToken token = new BTLToken();
        uint expected = 0;
        Assert.equal(token.balanceOf(msg.sender), expected, "Owner should have 0 BTL initially");
    }
}
