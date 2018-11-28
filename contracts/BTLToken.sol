pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";

// ----------------------------------------------------------------------------
// 'BTL Token' contract
// forked from '0xBitcoin Token' contract
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

    string public symbol = "BTL";
    string public name = "BTL Token";
    uint8 public decimals;
    uint public latestDifficultyPeriodStarted;
    uint public blockCount;//number of 'blocks' mined
    uint public _BLOCKS_PER_READJUSTMENT = 1024;
    //a little number
    uint public _MINIMUM_TARGET = 2**16;
    //a big number is easier ; just find a solution that is smaller
    uint public _MAXIMUM_TARGET = 2**234; // bitcoin uses 224
    uint public miningTarget;
    bytes32 public challengeNumber;   //generate a new one when a new reward is minted
    uint public rewardEra = 0;
    uint public cummulativeEraMaxSupply;
    address public lastRewardTo;
    uint public lastRewardAmount;
    uint public lastRewardEthBlockNumber;
    mapping(bytes32 => bytes32) solutionForChallenge;
    uint public tokensMinted = 0;
    event Mint(address indexed from, uint reward_amount, uint blockCount, bytes32 newChallengeNumber);
    uint public coins_count;
    uint public blocks_count;

    constructor (uint _coins_count, uint8 _decimals, uint _blocks_count, uint ownerBalancePercentage) public {
        coins_count = _coins_count.mul(10**uint(_decimals));
        blocks_count = _blocks_count;
        decimals = _decimals;
        _mint(msg.sender, coins_count.mul(ownerBalancePercentage).div(100));
        cummulativeEraMaxSupply = coins_count.div(2);
        miningTarget = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        _startNewMiningBlock();
    }

    function computeMintDigest(bytes32 challenge_number, address addr, uint nonce) public pure returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(challenge_number,addr,nonce));
    }

    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
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
        if(solution != 0x0) revert();  //prevent the same answer from awarding twice

        uint reward_amount = getMiningReward();

        _mint(msg.sender, reward_amount);

        tokensMinted = tokensMinted.add(reward_amount);

        //Cannot mint more tokens than there are
        assert(tokensMinted <= cummulativeEraMaxSupply);

        //set readonly diagnostics data
        lastRewardTo = msg.sender;
        lastRewardAmount = reward_amount;
        lastRewardEthBlockNumber = block.number;

        _startNewMiningBlock();

        emit Mint(msg.sender, reward_amount, blockCount, challengeNumber);

        return true;
    }

    function _startNewMiningBlock() internal {
        //40 is the final reward era, almost all tokens minted
        if(tokensMinted.add(getMiningReward()) > cummulativeEraMaxSupply && rewardEra < 39) {
            rewardEra = rewardEra + 1;
        }

        //set the next minted supply at which the era will change
        cummulativeEraMaxSupply = coins_count - coins_count.div(2**(rewardEra + 1));

        blockCount = blockCount.add(1);

        //every so often, readjust difficulty. Dont readjust when deploying
        if(blockCount % _BLOCKS_PER_READJUSTMENT == 0) {
            _reAdjustDifficulty();
        }

        //make the latest ethereum block hash a part of the next challenge for PoW to prevent pre-mining future blocks
        //do this last since this is a protection mechanism in the mint() function
        challengeNumber = blockhash(block.number - 1);
    }

    //https://en.bitcoin.it/wiki/Difficulty#What_is_the_formula_for_difficulty.3F
    //as of 2017 the bitcoin difficulty was up to 17 zeroes, it was only 8 in the early days

    //readjust the target by 5 percent
    function _reAdjustDifficulty() internal {
        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
        //assume 360 ethereum blocks per hour

        //we want miners to spend 10 minutes to mine each 'block', about 60 ethereum blocks = one 0xbitcoin epoch
        uint epochsMined = _BLOCKS_PER_READJUSTMENT; //256

        uint targetEthBlocksPerDiffPeriod = epochsMined * 60; //should be 60 times slower than ethereum

        //if there were less eth blocks passed in time than expected
        if(ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod)
        {
            uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(100)).div( ethBlocksSinceLastDifficultyPeriod );

            uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
            // If there were 5% more blocks mined than expected then this is 5.  If there were 100% more blocks mined than expected then this is 100.

            //make it harder
            miningTarget = miningTarget.sub(miningTarget.div(2000).mul(excess_block_pct_extra));   //by up to 50 %
        } else {
            uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(100)).div( targetEthBlocksPerDiffPeriod );

            uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000

          //make it easier
            miningTarget = miningTarget.add(miningTarget.div(2000).mul(shortage_block_pct_extra));   //by up to 50 %
        }

        latestDifficultyPeriodStarted = block.number;

        if(miningTarget < _MINIMUM_TARGET) //very difficult
        {
            miningTarget = _MINIMUM_TARGET;
        }

        if(miningTarget > _MAXIMUM_TARGET) //very easy
        {
            miningTarget = _MAXIMUM_TARGET;
        }
    }

    //this is a recent ethereum block hash, used to prevent pre-mining future blocks
    function getChallengeNumber() public view returns (bytes32) {
        return challengeNumber;
    }

    //the number of zeroes the digest of the PoW solution requires.  Auto adjusts
    // TODO: review
    function getMiningDifficulty() public view returns (uint) {
        return _MAXIMUM_TARGET.div(miningTarget);
    }

    function getMiningTarget() public view returns (uint) {
        return miningTarget;
    }

    //21m coins total
    //reward begins at 50 and is cut in half every reward era (as tokens are mined)
    //
    // Get mining reward for current era
    function getMiningReward() public view returns (uint) {
        //once we get half way thru the coins, only get 25 per block

        //every reward era, the reward amount halves.
        // TODO:
        return (10**uint(decimals)).div(2**rewardEra);
    }

    function getBlockReward(uint blockIndex) public view returns (uint) {
        int N = int(blocks_count);
        int M = int(coins_count);
        int numerator = 6*M*(99*(1 - int(blockIndex) * int(blockIndex)) + 100*(N*N - 1));
        int denominator = -99*N*(N+1)*(2*N+1) + 6*N*(100*N*N - 1);
        return uint(numerator / denominator);
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
