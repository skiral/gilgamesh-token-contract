/* eslint-disable */

const fs = require("fs");
const solc = require("solc");
const bluebird = require('bluebird');

const Web3 = require("web3");
const web3 = new Web3();

web3.setProvider(new web3.providers.HttpProvider("http://localhost:8545"));

const toEther = value => web3.fromWei(value, "ether");
const getBalance = addr => web3.eth.getBalance(addr).toNumber();
const toWei = value => web3.toWei(String(value), "ether");
const toTokenNumber = bNumber => bNumber.dividedBy(10 ** 18).toNumber();
const genToken = num => num * 10 ** 18;

class ContractHelper {
	constructor(
		contractSrc = ContractHelper.CONTRACT_SRC,
		contractName = ContractHelper.TOKEN_CONTRACT_NAME
	) {
		const source = fs.readFileSync(contractSrc, 'utf8');
		this.compiledContracts = solc.compile(source, 1);

		this.compiledContract = this.compiledContracts.contracts[':' + contractName];

		// Application Binary Interface (ABI)
		const abiArray = JSON.parse(this.compiledContract.interface);

		// creation of contract object
		this.contract = web3.eth.contract(abiArray);
	}

	setContractByAbi(abiArray) {
		this.contract =  web3.eth.contract(abiArray);
	}

	getInstanceByAddress(address = ContractHelper.CONTRACT_ADDRESS) {
		return this.contract.at(address);
	}

	deployContract(params = [], fromAddress, callback = function(){}) {

		this.deployerAddress = fromAddress;
		params.push({
			from: fromAddress,
			data: this.compiledContract.bytecode,
			gas: this.getGasEstimate() * 2 // because its going to be called twice
		})
		params.push((err, deployedContract) => {

			if (err) {
				console.log("transaction failed", err);
				return callback(err, null);
			}

			// e.g. check tx hash on the first call (transaction send)
			if(!deployedContract.address) {
				this.transactionHash = deployedContract.transactionHash;

				console.log('this.transactionHash', this.transactionHash);
				return;
				// return callback(err, {
				// 	transactionHash: this.transactionHash
				// });
			}

			this.contractAddress = deployedContract.address;

			return callback(err, {
				contractAddress: this.contractAddress,
				transactionHash: this.transactionHash
			});

		})

		return this.contract.new.apply(this.contract, params);

	}

	getCompiledContract() {
		return this.compiledContract;
	}

	getCompiledContracts() {
		return this.compiledContracts;
	}

	getGasEstimate() {
		let bytecode = this.compiledContract.bytecode;
		// return web3.eth.estimateGas({
		// 	data: bytecode
		// });
		return 1000000;
	}

	getContract() {
		return this.contract;
	}

	logCURL(data, from = this.deployerAddress, to = this.contractAddress) {
		var curlURL = 'curl -X POST --data ';
		var curlData = {
			jsonrpc: "2.0",
			method: "eth_sendTransaction",
			params: [{
				from,
				to,
				data
			}],
			id: 1
		};

		curlURL += "'"+JSON.stringify(curlData) + "'" + ' http://localhost:8545';

		console.log('curlURL', curlURL);
		return curlURL;
	}
}
ContractHelper.CONTRACT_SRC = './aggregated.sol';
ContractHelper.TOKEN_CONTRACT_NAME = 'GilgameshToken';
ContractHelper.CONTRACT_ADDRESS = '';

function objToArr(obj) {
	var arr = [];
	Object.keys(obj).forEach(record => {
		arr.push(obj[record]);
	})
	return arr;
}

( async () => {
	web3.eth.defaultAccount = web3.eth.accounts[0];
	const deployerAddress = web3.eth.accounts[0];
	const friend = web3.eth.accounts[1];

	const ch = new ContractHelper();
	const ch2 = new ContractHelper(ContractHelper.CONTRACT_SRC, 'GilgameshTokenSale');

	const gasEstimate = ch.getGasEstimate();
	const gas = 200 * 1000;
	//console.log('getGasEstimate', ch.getGasEstimate());


	/// 1- Run below code to create a token */
	// const deployContract = bluebird.promisify(ch.deployContract, { context: ch });
	// deployContract([], deployerAddress).then(data => {
	// 	console.log("data", data);
	// }).catch(e => {
	// 	console.log("e", e);
	// })


	/// 2- new instance - setup event handling
	// const tokenAddress = "0xf7ac20b5e31c1c11b21c0c165df516f0a60e83f0";
	// const instance = ch.getInstanceByAddress(tokenAddress);
	// var events = instance.allEvents();
	// events.watch(function(error, result) {
	// 	error && console.log('instance event error', error);
	// 	result && console.log('instance event result', result);
	// });


	/// 2.1- Run below code to create a token sale contract*/
	// var params = {
	// 	startBlock: 200,
	// 	endBlock: 300,
	// 	fundOwnerWallet: web3.eth.accounts[9],
	// 	tokenOwnerWallet: web3.eth.accounts[8],
	// 	totalStages: 5,
	// 	stageMaxBonusPercentage: 20,
	// 	tokenPrice:  2000, // 0.2 an ether
	// 	gilgameshToken: tokenAddress,
	// 	minimumCap: 5 * 10 ** 18 // 30 ether
	// }
	//
	// var paramsStr = {
	// 	startBlock: 200,
	// 	endBlock: 300,
	// 	fundOwnerWallet: '"' + web3.eth.accounts[9] + '"',
	// 	tokenOwnerWallet: '"' + web3.eth.accounts[8] + '"',
	// 	totalStages: 5,
	// 	stageMaxBonusPercentage: 20,
	// 	tokenPrice: '"' + 2000 + '"', // 0.2 an ether
	// 	gilgameshToken: '"' + tokenAddress + '"',
	// 	minimumCap: '"' + 10 ** 18 * 30 + '"' // 30 ether
	// };
	// console.log('str:', objToArr(paramsStr).join(','))
	//
	// const deployContract = bluebird.promisify(ch2.deployContract, { context: ch });
	// console.log("arr", objToArr(params));
	// deployContract(objToArr(params), deployerAddress).then(data => {
	// 	console.log("data", data);
	// }).catch(e => {
	// 	console.log("e", e);
	// })


	/// 2.2- new instance for tokensale - setup event handling
	// const tokenSaleAddress = '0x6877df44406532767b6a5ed421a6bc46a7c352d9';
	// const instanceTokenSale = ch2.getInstanceByAddress(tokenSaleAddress);
	// var eventsTokenSale = instanceTokenSale.allEvents();
	// eventsTokenSale.watch(function(error, result) {
	// 	error && console.log('instance event error', error);
	// 	result && console.log('instance event result', result);
	// });
	//
	// console.log("instanceTokenSale.creationBlock", instanceTokenSale.creationBlock().toNumber());


	/// 3- Run below code to get instance by address - static function
	// console.log('deployerAddress address', deployerAddress);
	// console.log("Total Supply", toTokenNumber(instance.totalSupply()));
	// console.log("admin Balance", toTokenNumber(instance.balanceOf(deployerAddress)));
	// console.log("friend Balance", toTokenNumber(instance.balanceOf(friend)));
	// console.log("name", instance.name());
	// console.log("symbol", instance.symbol());
	// console.log("decimals", instance.decimals().toNumber());
	// console.log("version", instance.version().toNumber());
	// console.log("admin", instance.admin());
	// console.log("minter", instance.minter());
	// console.log("creationBlock", instance.creationBlock().toNumber());
	// console.log("isTransferEnabled", instance.isTransferEnabled());

	/// logging curl call
	//ch.logCURL(instance.mint.getData(deployerAddress, genToken(1000)), deployerAddress);

	/// 4- minting transaction call - state changing function
	// instance.mint.sendTransaction(deployerAddress, genToken(1000), {
	// 	from: deployerAddress,
	// 	value: 0,
	// 	gasPrice: web3.eth.gasPrice,
	// 	gas: gasEstimate
	// }, (err, result) => {
	// 	console.log("minting", err, result);
	// }).then(()=> {}).catch(e => {
	// 	console.log("e", e);
	// })

	/// 4-1 minting by using method data.
	// web3.eth.sendTransaction({
	// 	data: instance.mint.getData(deployerAddress, genToken(1000)),
	// 	from: deployerAddress,
	// 	to: instance.address,
	// 	value: 0,
	// 	gasPrice: web3.eth.gasPrice,
	// 	gas: gasEstimate
	// }, (err, result) => {
	// 	console.log("minting", err, result);
	// }).then(()=> {}).catch(e => {
	// 	console.log("e", e);
	// })

	/// 5.1- disable token transfer by admin
	// instance.enableTransfers.sendTransaction(true, {
	// 	from: deployerAddress,
	// 	value: 0,
	// 	gasPrice: web3.eth.gasPrice,
	// 	gas: gasEstimate
	// });

	/// 5.2- disable token transfer by random user - it should fail
	// instance.enableTransfers.sendTransaction(true, {
	// 	from: friend,
	// 	value: 0,
	// 	gasPrice: web3.eth.gasPrice,
	// 	gas: gasEstimate
	// });

	/// 6- transfer tokens to a friend
	// instance.transfer.sendTransaction(friend, genToken(400), {
	// 	from: deployerAddress,
	// 	value: 0,
	// 	gasPrice: web3.eth.gasPrice,
	// 	gas: gasEstimate
	// }, (err, result) => {
	// 	console.log("transfer", err, result);
	// });



})();
