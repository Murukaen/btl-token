const BN = require('bn.js')
const abi = require('ethereumjs-abi')
const ProgressBar = require('progress')

module.exports = {
    buildDigest(challengeNumber, sender, nonce) {
        return abi.soliditySHA3(
            ["bytes32", "address", "uint"],
            [challengeNumber, sender, nonce]
        ).toString('hex')
    },
    bigNumberToBN(bigNumber) {
        return new BN(bigNumber.toString(16), 16)
    },
    async mine(contract, sender, tries = 10 ** 7) {
        const challengeNumber = await contract.getChallengeNumber.call() // string
        const receivedMiningTarget = await contract.getMiningTarget.call() // BigNumber
        const miningTarget = this.bigNumberToBN(receivedMiningTarget) 
        const receivedMininingReward = await contract.getMiningReward.call()
        const miningReward = this.bigNumberToBN(receivedMininingReward)
        const receivedTokensMinted = await contract.tokensMinted.call()
        const tokensMinted = this.bigNumberToBN(receivedTokensMinted)
        console.log("challengeNumber: ", challengeNumber);
        console.log("sender: ", sender);
        console.log("miningTarget: ", miningTarget.toString(16))
        console.log("miningReward: ", miningReward.toString(16))
        console.log("tokensMinted: ", tokensMinted.toString(16))
        const step = tries / 100
        let solutionFound = false
        let progressBar = new ProgressBar('attempt mine [:bar] :percent', { total: 100, width: 50 })
        for(i=1; i <= tries; i++) {
            if (i%step == 0) {
                progressBar.tick()
            }
            let nonce = new BN(i)
            let digest = this.buildDigest(challengeNumber, sender, nonce)
            if (new BN(digest, 16).lt(miningTarget)) {
                let result = await contract.mint('0x' + nonce.toString(16), '0x' + digest, {from: sender})
                console.log()
                console.log("tx result: ", result)
                console.log("nonce used: ", nonce.toString(16))
                console.log("digest: ", digest)
                solutionFound = true
                break
            }
        }
        assert.equal(solutionFound, true, "Mint solution was not found")
    }
}