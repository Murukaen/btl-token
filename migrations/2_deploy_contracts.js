const BTLToken = artifacts.require("./BTLToken.sol")

module.exports = function(deployer) {
  deployer.deploy(BTLToken, 4000000000, 8, 5256000, 60, 1, 0)
};
