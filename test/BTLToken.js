var BTLToken = artifacts.require("./BTLToken.sol")

contract('BTLToken', (accounts) => {
    it("initializes the contract with the correct values", async () => {
        let contract = await BTLToken.deployed()
        let tokenName = await contract.name()
        assert.equal(tokenName, "BTL Token")
        let tokenSymbol = await contract.symbol()
        assert.equal(tokenSymbol, "BTL")
    })
})
