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

library ExtendedMath {
    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {
        if(a > b) return b;
        return a;
    }
}

contract BTLToken is ERC20, Ownable {
    using ExtendedMath for uint;

    // TODO: decide below
    uint public READJUSTMENT_BLOCK_COUNT = 1024;
    // TODO: decide below
    uint public INITIAL_TARGET = 2**234;
    // TODO: decide below
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
    mapping(bytes32 => bytes32) solutionForChallenge;
    uint public tokensMinted;
    uint public coinsCount;
    uint public blocksCount;
    uint blockTime;
    uint lastBlockTimestamp;

    event Mint(address indexed from, uint reward_amount, uint blockCount, bytes32 newChallengeNumber);

    constructor (uint _coinsCount, uint8 _decimals, uint _blocksCount, uint _blockTime, uint ownerBalancePercentage) public {
        coinsCount = _coinsCount.mul(10**uint(_decimals));
        blocksCount = _blocksCount;
        decimals = _decimals;
        blockTime = _blockTime;
        _mint(msg.sender, coinsCount.mul(ownerBalancePercentage).div(100));
        miningTarget = INITIAL_TARGET;
        lastBlockTimestamp = block.timestamp;
        _startNewMiningBlock();
    }

    function computeMintDigest(bytes32 challenge_number, address addr, uint nonce) public pure returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(challenge_number,addr,nonce));
    }

    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
        require(blockCount <= blocksCount, "All blocks where mined");

        //the PoW must contain work that includes a recent ethereum block hash (challenge number) 
        //and the msg.sender's address to prevent MITM attacks
        bytes32 digest = computeMintDigest(challengeNumber, msg.sender, nonce);

        //the challenge digest must match the expected
        if (digest != challenge_digest) revert("Digest mismatch");

        //the digest must be smaller than the target
        if(uint256(digest) > miningTarget) revert("Digest is not within required bounds");

        //only allow one reward for each challenge
        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        // TODO: consider testing below revert
        if(solution != 0x0) revert();  //prevent the same answer from awarding twice

        uint reward_amount = getMiningReward();

        _mint(msg.sender, reward_amount);

        tokensMinted = tokensMinted.add(reward_amount);

        //set readonly diagnostics data
        lastRewardTo = msg.sender;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber = block.number;

        _startNewMiningBlock();

        emit Mint(msg.sender, reward_amount, blockCount, challengeNumber);

        return true;
    }

    function _startNewMiningBlock() internal {
        blockCount = blockCount.add(1);

        //every so often, readjust difficulty. Dont readjust when deploying
        if(blockCount % READJUSTMENT_BLOCK_COUNT == 0) {
            readjustDifficulty();
        }

        //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
        //do this last since this is a protection mechanism in the mint() function
        challengeNumber = blockhash(block.number - 1);
    }

    /**
     * Adjust miningTarget relative to indended blockTime
     */
    function readjustDifficulty() internal {
        uint actualBlockTime = (block.timestamp - lastBlockTimestamp).div(READJUSTMENT_BLOCK_COUNT);
        uint newTarget = miningTarget.mul(actualBlockTime).div(blockTime);
        if (newTarget > MAX_TARGET_FACTOR.mul(miningTarget)) {
            newTarget = MAX_TARGET_FACTOR.mul(miningTarget);
        }
        if (newTarget < miningTarget.div(MAX_TARGET_FACTOR)) {
            newTarget = miningTarget.div(MAX_TARGET_FACTOR);
        }
        miningTarget = newTarget;
        lastBlockTimestamp = block.timestamp;
    }

    //this is a recent ethereum block hash, used to prevent pre-mining future blocks
    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    function getMiningTarget() public view returns (uint) {
        return miningTarget;
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

    function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint target) 
        public view returns (bool success) {

        bytes32 digest = computeMintDigest(challenge_number, msg.sender, nonce);
        require(uint(digest) <= target, "Digest is out of target");
        return (digest == challenge_digest);
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert("Doesn't accept eth");
    }
}
