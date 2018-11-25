const BTLToken = artifacts.require("./BTLToken.sol")
const BN = require('bn.js')
const miningHelper = require('./mining-helper.js')

contract('BTLToken', (accounts) => {
    let contract

    beforeEach('setup contract for each test', async () => {
        contract = await BTLToken.deployed() 
    })

    it("initializes the contract with the correct values", async () => {
        const tokenName = await contract.name()
        assert.equal(tokenName, "BTL Token")
        const tokenSymbol = await contract.symbol()
        assert.equal(tokenSymbol, "BTL")
    })

    it("mints coins", async () => {
        const challengeNumber = await contract.getChallengeNumber.call() // string
        const receivedMininingReward = await contract.getMiningReward.call()
        const miningReward = new BN(receivedMininingReward.toString(16), 16)
        const sender = accounts[0]
        let initialBalance = await contract.balanceOf.call(sender)
        assert.equal(initialBalance.toNumber(), 0, "Initial balance should be 0")
        // mint attempt with wrong digest shld fail
        try {
            await contract.mint(1, '0x' + '0'.repeat(32))
            assert.fail()
        } catch (err) {
            assert.ok(/Digest mismatch/.test(err))
            assert.ok(/revert/.test(err))
        }
        // mint attempt with digest above target shld fail
        try {
            let nonce = new BN(1)
            let digest = miningHelper.buildDigest(challengeNumber, sender, nonce)
            await contract.mint('0x' + nonce.toString(16), '0x' + digest)
            assert.fail()
        } catch (err) {
            assert.ok(/Digest is not within required bounds/.test(err))
            assert.ok(/revert/.test(err))
        }
        // look for valid digest
        await miningHelper.mine(contract, sender)
        let balance = await contract.balanceOf.call(sender)
        assert.equal(balance.toNumber(), miningReward.toNumber(), "Balance after mint should equal mining reward")
    })
})
