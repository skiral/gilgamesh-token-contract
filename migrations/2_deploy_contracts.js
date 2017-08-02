var ConvertLib = artifacts.require("./ConvertLib.sol");
var MetaCoin = artifacts.require("./MetaCoin.sol");
var GilgameshToken = artifacts.require("./GilgameshToken.sol");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin, GilgameshToken);
  deployer.deploy(MetaCoin);
  deployer.deploy(GilgameshToken);
};
