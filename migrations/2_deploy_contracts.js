var BTLToken = artifacts.require("./BTLToken.sol")

module.exports = function(deployer) {
  deployer.deploy(BTLToken)
};
