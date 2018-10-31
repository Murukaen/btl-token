const BTLToken = artifacts.require("./BTLToken.sol")
const abi = require('ethereumjs-abi')
const BN = require('bn.js')

contract('BTLToken', (accounts) => {
    it("initializes the contract with the correct values", async () => {
        const contract = await BTLToken.deployed()
        const tokenName = await contract.name()
        assert.equal(tokenName, "BTL Token")
        const tokenSymbol = await contract.symbol()
        assert.equal(tokenSymbol, "BTL")
    }),
    it("mints coins", async () => {
        const contract = await BTLToken.deployed()
        const challengeNumber = await contract.getChallengeNumber.call() // string
        const receivedMiningTarget = await contract.getMiningTarget.call() // BigNumber
        const miningTarget = new BN(receivedMiningTarget.toString(16), 16) 
        const receivedMininingReward = await contract.getMiningReward.call()
        const miningReward = new BN(receivedMininingReward.toString(16), 16)
        const sender = accounts[0]
        console.log("challengeNumber: ", challengeNumber);
        console.log("sender: ", sender);
        console.log("miningTarget: ", miningTarget.toString(16))
        console.log("miningReward: ", miningReward.toString(16))
        let initialBalance = await contract.balanceOf.call(sender)
        assert.equal(initialBalance.toNumber(), 0, "Initial balance should be 0")

        const N = 10**7
        const step = 10**4
        solutionFound = false
        for(i=0; i < N; i++) {
            if (i%step == 0) {
                console.log(`mining step [${i/step}/${N/step - 1}]`)
            }
            let nonce = new BN(i)

            let digest = abi.soliditySHA3(
                ["bytes32", "address", "uint"],
                [challengeNumber, sender, nonce]
            ).toString('hex')

            if (new BN(digest, 16).lt(miningTarget)) {
                let result = await contract.mint('0x' + nonce.toString(16), '0x' + digest, {from: sender})
                console.log("tx result: ", result)
                console.log("nonce used: ", nonce.toString(16))
                console.log("digest: ", digest)
                solutionFound = true
                break
            }
        }
        assert.equal(solutionFound, true, "Mint solution was not found")
        let balance = await contract.balanceOf.call(sender)
        assert.equal(balance.toNumber(), miningReward.toNumber(), "Balance after mint should equal mining reward")
    })
})
