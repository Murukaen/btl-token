const suite = require('../node_modules/token-test-suite/lib/suite')
const BTLToken = artifacts.require('BTLToken')

contract('BTLToken', function (accounts) {
	let options = {
		// accounts to test with, accounts[0] being the contract owner
		accounts: accounts,

		// factory method to create new token contract
		create: async function () {
			return await BTLToken.new(1000, 2, 100, 600, 5, 50); // allocate 50% of total supply to owner, for testing purposes
		},

		// factory callbacks to mint the tokens
		// use "transfer" instead of "mint" for non-mintable tokens
		transfer: async function (token, to, amount) {
			return await token.transfer(to, amount, { from: accounts[0] , gas: 200000});
		},

		// optional:
		// also test the increaseApproval/decreaseApproval methods (not part of the ERC-20 standard)
		increaseDecreaseApproval: false,

		// token info to test
		name: 'BTL Token',
		symbol: 'BTL',
		decimals: 2,

		// initial state to test
		initialSupply: 50000,
		initialBalances: [
			[accounts[0], 50000]
		],
		initialAllowances: [

        ]
    };
	suite(options);
});