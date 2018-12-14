pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// ----------------------------------------------------------------------------
// 'BTL Token' contract
// Mineable ERC20 Token using Proof Of Work
//
// Symbol      : BTL
// Name        : BTL Token
// ----------------------------------------------------------------------------

contract BTLToken is ERC20, Ownable {
    // TODO: decide below
    uint public INITIAL_TARGET = 2**234;
    // TODO: decide below
    // Max factor to be applied as an update to the mining target from a dificulty recalibration
    uint public MAX_TARGET_FACTOR = 2**2;
    string public symbol = "BTL";
    string public name = "BTL Token";
    uint8 public decimals;
    uint public blockCount; //number of blocks mined
    uint public miningTarget;
    bytes32 public challengeNumber; //a new one is generated after every block
    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    uint public tokensMinted;
    uint public coinsCount;
    uint public blocksCount;
    uint public blockTime;
    uint private lastBlockTimestamp;
    uint private difficultyReadjustmentBlockCount;

    event Mint(address indexed from, uint reward_amount, uint blockCount, bytes32 newChallengeNumber);

    constructor (uint _coinsCount, uint8 _decimals, uint _blocksCount, uint _blockTime, 
        uint _difficultyReadjustmentBlockCount, uint ownerBalancePercentage) public {
        coinsCount = _coinsCount.mul(10**uint(_decimals));
        blocksCount = _blocksCount;
        decimals = _decimals;
        blockTime = _blockTime;
        difficultyReadjustmentBlockCount = _difficultyReadjustmentBlockCount;
        _mint(msg.sender, coinsCount.mul(ownerBalancePercentage).div(100));
        miningTarget = INITIAL_TARGET;
        lastBlockTimestamp = now;
        startNewMiningBlock();
    }

    function computeMintDigest(bytes32 challenge_number, address addr, uint nonce) public pure returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(challenge_number,addr,nonce));
    }

    function mint(uint256 nonce, bytes32 challenge_digest) external returns (bool success) {
        require(blockCount <= blocksCount, "All blocks where mined");

        //the PoW must contain work that includes a recent ethereum block hash (challenge number) 
        //and the msg.sender's address to prevent MITM attacks
        bytes32 digest = computeMintDigest(challengeNumber, msg.sender, nonce);

        //the challenge digest must match the expected
        require(digest == challenge_digest, "Digest mismatch");

        //the digest must be smaller than the target
        require(uint256(digest) <= miningTarget, "Digest is not within required bounds");

        uint reward_amount = getMiningReward();

        _mint(msg.sender, reward_amount);

        tokensMinted = tokensMinted.add(reward_amount);

        //set readonly diagnostics data
        lastRewardTo = msg.sender;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber = block.number;

        startNewMiningBlock();

        emit Mint(msg.sender, reward_amount, blockCount, challengeNumber);

        return true;
    }

    function startNewMiningBlock() internal {
        //every so often, readjust difficulty. Dont readjust when deploying
        if(blockCount > 0 && blockCount % difficultyReadjustmentBlockCount == 0) {
            readjustDifficulty();
        }

        blockCount = blockCount.add(1);

        //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
        //do this last since this is a protection mechanism in the mint() function
        challengeNumber = blockhash(block.number - 1);
    }

    /**
     * Adjust miningTarget relative to indended blockTime
     */
    function readjustDifficulty() internal {
        uint actualBlockTime = (now - lastBlockTimestamp).div(difficultyReadjustmentBlockCount);
        uint newTarget = miningTarget.mul(actualBlockTime).div(blockTime);
        if (newTarget > MAX_TARGET_FACTOR.mul(miningTarget)) {
            newTarget = MAX_TARGET_FACTOR.mul(miningTarget);
        }
        if (newTarget < miningTarget.div(MAX_TARGET_FACTOR)) {
            newTarget = miningTarget.div(MAX_TARGET_FACTOR);
        }
        miningTarget = newTarget;
        lastBlockTimestamp = now;
    }

    /**
     * Coin distribution scheme
     */
    function getBlockReward(uint blockIndex) public view returns (uint) {
        int N = int(blocksCount);
        int M = int(coinsCount);
        int numerator = 6*M*(99*(1 - int(blockIndex) * int(blockIndex)) + 100*(N*N - 1));
        int denominator = -99*N*(N+1)*(2*N+1) + 6*N*(100*N*N - 1);
        return uint(numerator / denominator);
    }

    /** 
     * Get mining reward for current block
     */
    function getMiningReward() public view returns (uint) {
        return getBlockReward(blockCount);
    }

    /**
     * Helper function to validate digest relative to a target   
     */
    function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint target) 
        external view returns (bool success) {
        bytes32 digest = computeMintDigest(challenge_number, msg.sender, nonce);
        require(uint(digest) <= target, "Digest is out of target");
        return (digest == challenge_digest);
    }

    /**
     * Don't let contract accept direct ETH payments
     */
    function () public payable {
        revert("Doesn't accept eth");
    }
}
