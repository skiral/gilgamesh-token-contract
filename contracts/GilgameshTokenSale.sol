pragma solidity ^0.4.11;

import "./SafeMath.sol";
import "./GilgameshToken.sol";

/*
	Copyright 2017, Skiral Inc
*/
contract GilgameshTokenSale is SafeMath{

	// `creationBlock` is the block number that the Token was created
	uint256 public creationBlock;

	// `startBlock` token sale starting block
	uint256 public startBlock;

	// `endBlock` token sale ending block
	uint256 public endBlock;

	// total Wei rasised
	uint256 public totalRaised = 0;

	// Has Gilgamesh stopped the sale
	bool public saleStopped = false;

	// Has Gilgamesh finalized the sale
	bool public saleFinalized = false;

	// Minimum investment - 0.001 Ether
	uint256 constant public minimumInvestment = 1 finney;

	// Hard cap to protect the ETH network from a really high raise
	uint256 public hardCap = 1000000 ether;

	// minimum cap
	uint256 public minimumCap = 5000 ether;

	/* Contract Info */

	// `fundOwnerWallet` the deposit address for the `Eth` that is raised.
	address public fundOwnerWallet;

	// `creator` the address of the contract depoloyer
	address public creator;

	// `stageBonusPercentage`
	uint[] public stageBonusPercentage;

	// `totalStages`
	uint8 public totalStages;

	uint8 public stageMaxBonusPercentage;

	// price of token per wei
	uint256 public tokenPrice;

	// the team owns 80% of the tokens - 4 times more than investors.
	uint8 public teamTokenRatio = 4;

	// The token
	GilgameshToken public token;

	event LogTokenSaleInitialized(
		address creator,
		address fundOwnerWallet,
		uint256 startBlock,
		uint256 endBlock
	);

	event LogContribution(
		address contributorAddress,
		uint265 amount,
		uint256 totalRaised
	);

	event LogFinalized(uint256 teamTokens);

	// Constructor
	function GilgameshTokenSale(
		uint256 _startBlock,
		uint256 _endBlock,
		address _fundOwnerWallet,
		uint8 _totalStages,
		uint8 _stageMaxBonusPercentage,
		uint256 _tokenPrice,
		address _gilgameshToken,
		uint256 _minimumCap
	)
	validate_address(_fundOwnerWallet)
	validate_address(_gilgameshToken) {
		// start block needs to be in the future
		if (_startBlock < block.number) throw;

		// start block should be less than ending block
		if (_startBlock >= _endBlock) throw;

		if (_totalStages < 2) throw;

		if(_stageMaxBonusPercentage <= 0 ) throw;

		// stage bonus percentage needs to be devisible by number of stages
		if (_stageMaxBonusPercentage % _totalStages != 0) throw;

		creator = msg.sender;
		fundOwnerWallet = _fundOwnerWallet;
		startBlock = _startBlock;
		endBlock = _endBlock;
		token = GilgameshToken(_gilgameshToken);

		tokenPrice = _tokenPrice;
		totalRaised = 0;
		totalStages = _totalStages;
		stageMaxBonusPercentage = _stageMaxBonusPercentage;
		minimumCap = _minimumCap;

		// spread bonuses evenly between stages - e.g 20 / 4 = 5%
		// e.g
		// stageMaxBonusPercentage = 80
		// totalStages = 5
		// spread = 20
		// stageBonusPercentage [80, 66, 40, 20, 0]
		uint spread = stageMaxBonusPercentage / (totalStages - 1);
		for (uint stageNumber = totalStages - 1; stageNumber >= 0; stageNumber--) {
			stageBonusPercentage.push(stageNumber * spread);
		}

		LogTokenSaleInitialized(
			creator,
			fundOwnerWallet,
			startBlock,
			endBlock
		);
	}

	// --------------
	// Public Funtions
	// --------------

	// @notice Function to stop sale for an emergency.
	// @dev Only Gilgamesh Dev can do it after it has been activated.
	function emergencyStopSale()
		only_sale_active
		only(creator)
		public {
		saleStopped = true;
	}

	// @notice Function to restart stopped sale.
	// @dev Only Gilgamesh Dev can do it after it has been disabled and sale is ongoing.
	function restartSale()
		only_during_sale_period
		only_sale_stopped
		only(creator)
		public {
			saleStopped = false;
	}

	function changeFundOwnerWalletAddress(address _fundOwnerWallet)
		validate_address(_fundOwnerWallet)
		only(owner)
		public {

		fundOwnerWallet = _fundOwnerWallet;
	}

	function finalizeSale()
	only(owner)
	public {
		doFinalizeSale();
	}

	function changeCap(uint256 _cap)
	only(owner)
	public {
		if (_cap >= hardCap) throw;
		if (_cap < minimumCap) throw;
		
		hardCap = _cap;

		if (totalRaised + minimumInvestment >= hardCap) {
			doFinalizeSale();
		}
	}


	/// @dev The fallback function is called when ether is sent to the contract, it
	/// simply calls `doPayment()` with the address that sent the ether as the
	/// `_owner`. Payable is a required solidity modifier for functions to receive
	/// ether, without this modifier functions will throw if ether is sent to them
	function () public payable {
		return doPayment(msg.sender);
	}

	// --------------
	// Internal Funtions
	// --------------

	///	@dev `doPayment()` is an internal function that sends the ether that this
	///	contract receives to the gilgameshFund and creates tokens in the address of the
	///	@param _owner The address that will hold the newly created tokens
	function doPayment(address _owner)
	only_sale_active
	minimum_contribution()
	validate_address(_owner)
	internal {
		// if it passes hard cap throw
		if (totalRaised + msg.value > hardCap) throw;

		uint256 userTokens = calculateTokens(msg.value);

		// if user tokens are 0 throw
		if (userTokens <= 0) throw;

		// send funds to fund owner wallet
		if (!fundOwnerWallet.send(msg.value)) throw;

		// mint tokens for the user
		if (!token.mint(msg.sender, userTokens)) throw;

		// save total number wei raised
		totalRaised = safeAdd(totalRaised, msg.value);

		if (totalRaied >= hardCap) {
			isCapReached = true;
		}

		LogContribution(msg.sender, msg.value, totalRaised);
	}

	function calculateTokens(uint256 amount)
	internal
	returns (uint256) {
		if (block.number < startBlock || block.number >= endBlock) return 0;

		uint8 currentStage = getStageByBlockNumber(block.number);

		if (currentStage > totalStages) return 0;

		uint256 purchasedTokens = safeDiv(amount, tokenPrice);
		uint256 rewardedTokens = calculateReward(amount, currentStage);

		return safeAdd(purchasedTokens, rewardedTokens);
	}

	function calculateReward(uint256 amount, uint8 stageNumber)
	internal
	returns (uint256 rewardAmount) {
		if (stageNumber < 1) throw;
		if (currentStage > totalStages) throw;

		uint8 stageIndex = stageNumber - 1;

		return safeDiv(safeMul(amount, stageBonusPercentage[stageIndex]), 100);
	}

	function getStageByBlockNumber(uint256 _blockNumber)
	internal
	returns (uint8) {

		uint256 numOfBlockPassed = safeSub(_blockNumber, startBlock);
		uint256 totalBlocks = safeSub(endBlock, startBlock);

		return uint8(safeDiv(safeMul(totalStages, numOfBlockPassed), totalBlocks));
	}

	function doFinalizeSale()
	only(owner)
	internal {
		uint256 teamTokens = safeMul(token.totalSupply(), teamTokenRatio);

		// mint tokens for the team
		if (!token.mint(creator, teamTokens)) throw;

		saleFinalized = true;
		saleStopped = true;

		LogFinalized(teamTokens);
	}

	// --------------
	// Modifiers
	// --------------

	modifier only_sale_stopped {
		if (!saleStopped) throw;
		_;
	}

	modifier validate_address(address _address) {
		if (_address == 0) throw;
		_;
	}

	modifier only_during_sale_period {
		// if block number is less than starting block fail
		if (block.number < startBlock) throw;
		// if block number has reach to the end block fail
		if (block.number >= endBlock) throw;
		// otherwise safe to continue
		_;
	}

	modifier only_sale_active {
		// if sale is finalized fail
		if (saleFinalized) throw;
		// if sale is stopped fail
		if (saleStopped) throw;
		// if block number is less than starting block fail
		if (block.number < startBlock) throw;
		// if block number has reach to the end block fail
		if (block.number >= endBlock) throw;
		// otherwise safe to continue
		_;
	}

	modifier minimum_contribution() {
		if (msg.value < minimumInvestment) throw;
		_;
	}

	modifier only(address x) {
		if (msg.sender != x) throw;
		_;
	}
}
