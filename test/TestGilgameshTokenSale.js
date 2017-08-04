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
	let token;

	beforeEach(async () => {
		token = await GilgameshToken.deployed();
	});

	const createTokenSale = async ({
		startBlock = 1000,
		endBlock = 2000,
		fundOwnerWallet = accounts[ 1 ],
		tokenOwnerWallet = accounts[ 2 ],
		totalStages = 2,
		stageMaxBonusPercentage = 20,
		tokenPrice = 10 ** 18 / 1000,
		minimumCap = 5 * 10 ** 18,
		owner = accounts[ 0 ],
		gilgameshToken,
		blockNumber = 1,
	} = {}) => {
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
			// instantiate a new contract
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

		await token.changeMinter(sale.address);

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

		it("total number of blocks needs to be devisible by the total stages", async () => {
			assertChai.isRejected(createTokenSale({ startBlock: 20, endBlock: 30, totalStages: 20 }));
			assertChai.isFulfilled(createTokenSale({ startBlock: 20, endBlock: 30, totalStages: 10 }));
		});
	});

	const toEther = value => web3.fromWei(value, "ether");
	const getBalance = addr => web3.eth.getBalance(addr).toNumber();
	const toWei = value => web3.toWei(String(value), "ether");

	describe.skip("deposit() test cases", () => {
		it("receive token for successuful payment", async () => {
			const userAddress = accounts[ 4 ];
			const sale = await createTokenSale({
				startBlock: 900,
			});
			const tokenBalance = await token.balanceOf(userAddress);
			console.log("token minter", await token.minter());
			console.log("sale address", sale.address);
			console.log("token balance", tokenBalance.valueOf());
			console.log("ether balance", toEther(getBalance(userAddress)));

			assert.isOk("everything", "everything is ok");

			await sale.setMockedBlockNumber(1000);

			// await sale.deposit({
			// 	value: toWei(0.1),
			// 	from: userAddress,
			// });
			// console.log("toWei(0.1)", toWei(0.1));
			// console.log("number of tokens", (await sale.calculateTokens(toWei(0.1))).valueOf());

			// console.log(await token.balanceOf(accounts[ 4 ]));
		});
	});

	describe.skip("isDuringSalePeriod() test cases", () => {
		it("should return false for block numbers less than starting block ", async () => {
			const sale = await createTokenSale({
				startBlock: 900,
			});
			// using `.call` to explicitly call the method rather than the transaction.
			assert.isFalse(await sale.isDuringSalePeriodMock.call(800));
		});

		it("should return true for block numbers between the starting block and end block", async () => {
			const sale = await createTokenSale({
				startBlock: 900,
				endBoock: 1000,
			});

			assert.isTrue(await sale.isDuringSalePeriodMock.call(900));
			assert.isTrue(await sale.isDuringSalePeriodMock.call(950));
			assert.isTrue(await sale.isDuringSalePeriodMock.call(999));
		});

		it("should return false for block numbers more than end block", async () => {
			const sale = await createTokenSale({
				startBlock: 900,
				endBlock: 1000,
			});

			assert.isFalse(await sale.isDuringSalePeriodMock.call(1000));
			assert.isFalse(await sale.isDuringSalePeriodMock.call(1001));
		});
	});

	describe("getStageByBlockNumber() test cases", () => {
		it("test all use cases for getStageByBlockNumber() function", async () => {
			let sale = await createTokenSale({
				startBlock: 10,
				endBlock: 20,
				totalStages: 2,
				stageMaxBonusPercentage: 20,
			});

			// helper function
			// needs .toNumber() because it returns a bigNumber
			const getStageByBlockNumber = async blockNumber => (await sale.getStageByBlockNumberMock.call(blockNumber)).toNumber();

			assertChai.isRejected(sale.getStageByBlockNumberMock.call(9));
			assertChai.isRejected(sale.getStageByBlockNumberMock.call(20));

			// 10 to 14 are at stage 1
			assert.equal(await getStageByBlockNumber(10), 1);
			assert.equal(await getStageByBlockNumber(11), 1);
			assert.equal(await getStageByBlockNumber(12), 1);
			assert.equal(await getStageByBlockNumber(13), 1);
			assert.equal(await getStageByBlockNumber(14), 1);
			// // 14 to 20 are at stage 2
			assert.equal(await getStageByBlockNumber(15), 2);
			assert.equal(await getStageByBlockNumber(16), 2);
			assert.equal(await getStageByBlockNumber(17), 2);
			assert.equal(await getStageByBlockNumber(18), 2);
			assert.equal(await getStageByBlockNumber(19), 2);

			sale = await createTokenSale({
				startBlock: 10,
				endBlock: 20,
				totalStages: 5,
				stageMaxBonusPercentage: 20,
			});

			assert.equal(await getStageByBlockNumber(10), 1);
			assert.equal(await getStageByBlockNumber(11), 1);
			assert.equal(await getStageByBlockNumber(12), 2);
			assert.equal(await getStageByBlockNumber(13), 2);
			assert.equal(await getStageByBlockNumber(14), 3);
			assert.equal(await getStageByBlockNumber(15), 3);
			assert.equal(await getStageByBlockNumber(16), 4);
			assert.equal(await getStageByBlockNumber(17), 4);
			assert.equal(await getStageByBlockNumber(18), 5);
			assert.equal(await getStageByBlockNumber(19), 5);

			sale = await createTokenSale({
				startBlock: 10,
				endBlock: 20,
				totalStages: 10,
				stageMaxBonusPercentage: 20,
			});

			assert.equal(await getStageByBlockNumber(10), 1);
			assert.equal(await getStageByBlockNumber(11), 2);
			assert.equal(await getStageByBlockNumber(12), 3);
			assert.equal(await getStageByBlockNumber(13), 4);
			assert.equal(await getStageByBlockNumber(14), 5);
			assert.equal(await getStageByBlockNumber(15), 6);
			assert.equal(await getStageByBlockNumber(16), 7);
			assert.equal(await getStageByBlockNumber(17), 8);
			assert.equal(await getStageByBlockNumber(18), 9);
			assert.equal(await getStageByBlockNumber(19), 10);
		});
	});
});
