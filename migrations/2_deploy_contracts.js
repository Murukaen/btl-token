const BTLToken = artifacts.require("./BTLToken.sol")

module.exports = function(deployer) {
  deployer.deploy(BTLToken, 0)
};
