const GilgameshTokenSaleMock = artifacts.require("./GilgameshTokenSaleMock.sol");
const GilgameshToken = artifacts.require("./GilgameshToken.sol");

const MetaCoin = artifacts.require("./MetaCoin.sol");

const chai = require("chai");
const chaiAsPromised = require("chai-as-promised");

chai.use(chaiAsPromised);
const expect = chai.expect;
const assertChai = chai.assert;

const INVALID_OPCODE = "VM Exception while processing transaction: invalid opc";

contract("TestGilgameshTokenSale", (accounts) => {
	const createTokenSale = async ({
		startBlock = 100,
		endBlock = 200,
		fundOwnerWallet = accounts[ 1 ],
		tokenOwnerWallet = accounts[ 2 ],
		totalStages = 2,
		stageMaxBonusPercentage = 20,
		tokenPrice = 10 ** 18,
		minimumCap = 5 * 10 ** 18,
		owner = accounts[ 0 ],
		gilgameshToken,
		blockNumber = 1,
	}) => {
		const token = await GilgameshToken.deployed();

		gilgameshToken = gilgameshToken === undefined ? token.address : gilgameshToken;

		const tokenSaleParams = [
			startBlock, // starting block number
			endBlock, // ending block number
			fundOwnerWallet, // fund owner wallet address - transfer ether to this address after fund has been closed
			tokenOwnerWallet, // token fund owner wallet address - transfer GIL tokesn to this address after fund is finalized
			totalStages, // total number of bonus stages
			stageMaxBonusPercentage, // maximum percentage for bonus in the first stage
			tokenPrice, // price of each token in wei
			gilgameshToken, // address of the gilgamesh ERC20 token contract
			minimumCap, // minimum cap, minimum amount of wei to be raised
			blockNumber, // override the current block number
		];
		let sale;
		try {
			sale = await GilgameshTokenSaleMock.new(...tokenSaleParams, { from: owner });
		} catch (e) {
			throw new Error(e);
		}

		assert.equal(await sale.startBlock(), startBlock, "`startBlock` should match");
		assert.equal(await sale.endBlock(), endBlock, "`endBlock` should match");
		assert.equal(await sale.fundOwnerWallet(), fundOwnerWallet, "`fundOwnerWallet` should match");
		assert.equal(await sale.tokenOwnerWallet(), tokenOwnerWallet, "`tokenOwnerWallet` should match");
		assert.equal(await sale.tokenPrice(), tokenPrice, "`tokenPrice` should match");
		assert.equal(await sale.token(), token.address, "`token` should match");
		assert.equal(await sale.minimumCap(), minimumCap, "`minimumCap` should match");
		assert.equal(await sale.totalStages(), totalStages, "`totalStages` should match");
		assert.equal(await sale.stageMaxBonusPercentage(), stageMaxBonusPercentage, "`stageMaxBonusPercentage` should match");

		return sale;
	};

	describe("token be deployed sucessfully deployment", () => {
		it("default parameters", () => {
			createTokenSale();
		});

		it("invalid fundOwnerWallet should fail", () => {
			assertChai.isRejected(createTokenSale({ fundOwnerWallet: 0x0 }));
		});

		it("invalid tokenOwnerWallet should fail", () => {
			assertChai.isRejected(createTokenSale({ tokenOwnerWallet: 0x0 }));
		});

		it("start block should be less than ending block", async () => {
			assertChai.isRejected(createTokenSale({ startBlock: 100, endBlock: 100 }));
			assertChai.isRejected(createTokenSale({ startBlock: 100, endBlock: 99 }));
		});

		it.skip("start block after the current block", async () => {
			assertChai.isRejected(createTokenSale({ startBlock: 100, blockNumber: 110 }));
			//
			// const startBlock = await (await createTokenSale({ startBlock: 100, blockNumber: 110 })).startBlock();
			// console.log("startBlock", startBlock);
		});

		it("Total stages should be more than or equal 2", async () => {
			assertChai.isRejected(createTokenSale({ totalStages: 1 }));
			assertChai.isFulfilled(createTokenSale({ totalStages: 2 }));
		});

		it("`stageMaxBonusPercentage` should be in a range of 0 to 100", async () => {
			assertChai.isRejected(createTokenSale({ stageMaxBonusPercentage: 101 }));
			assertChai.isFulfilled(createTokenSale({ stageMaxBonusPercentage: 80 }));
		});

		it("stage bonus percentage needs to be devisible by number of stages", async () => {
			assertChai.isRejected(createTokenSale({ stageMaxBonusPercentage: 80, totalStages: 3 }));
			assertChai.isFulfilled(createTokenSale({ stageMaxBonusPercentage: 80, totalStages: 4 }));
		});
	});
});
