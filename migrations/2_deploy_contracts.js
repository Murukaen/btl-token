var BTLToken = artifacts.require("./BTLToken.sol")
var TestContract = artifacts.require("./TestContract.sol")

module.exports = function(deployer) {
  deployer.deploy(BTLToken)
  deployer.deploy(TestContract)
};
