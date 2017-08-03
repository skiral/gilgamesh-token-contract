var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var GilgameshToken = artifacts.require("./GilgameshToken.sol");
var SecureERC20Token = artifacts.require("./SecureERC20Token.sol");
var GilgameshTokenSale = artifacts.require("./GilgameshTokenSale.sol");

module.exports = function(deployer, network, accounts) {

	// only deploy it on Development instance
	if (network !== 'development') return;

	deployer.deploy(ConvertLib);
	deployer.link(ConvertLib, MetaCoin, GilgameshToken, SecureERC20Token);
	deployer.deploy(MetaCoin);

	deployer.deploy(GilgameshToken);

	// deploy SecureERC20Token - pass arguments after the first
	var secureERC20TokenArguments = [
		1000, // initialSupply
		"Gilgamesh", // name
		"GIL",	// Symbol
		18, // decimals
		true // isTransfereEnable
	];
	deployer.deploy(SecureERC20Token, ...secureERC20TokenArguments);

	//	deployer.deploy(GilgameshTokenSale);
};
