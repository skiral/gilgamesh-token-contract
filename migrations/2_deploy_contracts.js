const GilgameshToken = artifacts.require("./GilgameshToken.sol");
const SecureERC20Token = artifacts.require("./SecureERC20Token.sol");
const GilgameshTokenSale = artifacts.require("./GilgameshTokenSale.sol");

module.exports = function (deployer, network, accounts) {
	// only deploy it on Development instance
	if (network !== "development") return;

	deployer.deploy(GilgameshToken);

	// deploy SecureERC20Token - pass arguments after the first
	const secureERC20TokenArguments = [
		1000, // initialSupply
		"Gilgamesh", // name
		"GIL",	// Symbol
		18, // decimals
		true, // isTransfereEnable
	];

	deployer.deploy(SecureERC20Token, ...secureERC20TokenArguments);

	//	deployer.deploy(GilgameshTokenSale);
};
