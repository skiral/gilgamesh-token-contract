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
		return web3.eth.estimateGas({
			data: bytecode
		});
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
ContractHelper.CONTRACT_SRC = '../contracts/aggregated.sol';
ContractHelper.TOKEN_CONTRACT_NAME = 'GilgameshToken';
ContractHelper.CONTRACT_ADDRESS = '';



( async () => {

	const deployerAddress = web3.eth.accounts[0];
	const friend = web3.eth.accounts[1];

	const ch = new ContractHelper();
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
	const instance = ch.getInstanceByAddress("0x6d716febf32c95ff33f686a017d4bac524b11e49");
	var events = instance.allEvents();
	events.watch(function(error, result) {
		error && console.log('instance event error', error);
		result && console.log('instance event result', result);
	});

	/// 3- Run below code to get instance by address - static function
	console.log('deployerAddress address', deployerAddress);
	console.log("Total Supply", toTokenNumber(instance.totalSupply()));
	console.log("admin Balance", toTokenNumber(instance.balanceOf(deployerAddress)));
	console.log("friend Balance", toTokenNumber(instance.balanceOf(friend)));
	console.log("name", instance.name());
	console.log("symbol", instance.symbol());
	console.log("decimals", instance.decimals().toNumber());
	console.log("version", instance.version().toNumber());
	console.log("admin", instance.admin());
	console.log("minter", instance.minter());
	console.log("creationBlock", instance.creationBlock().toNumber());
	console.log("isTransferEnabled", instance.isTransferEnabled());

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
