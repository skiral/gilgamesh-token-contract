pragma solidity ^0.4.11;

import "./SafeMath.sol";
import "./GilgameshToken.sol";

/*
	Copyright 2017, Skiral Inc
*/
contract GilgameshTokenSale is SafeMath{

	// creationBlock is the block number that the Token was created
	uint256 public creationBlock;

	// startBlock token sale starting block
	uint256 public startBlock;

	// endBlock token sale ending block
	// end block is not a valid block for crowdfunding. endBlock - 1 is the last valid block
	uint256 public endBlock;

	// total Wei rasised
	uint256 public totalRaised = 0;

	// Has Gilgamesh stopped the sale
	bool public saleStopped = false;

	// Has Gilgamesh finalized the sale
	bool public saleFinalized = false;

	// Minimum investment - 0.01 Ether
	uint256 constant public minimumInvestment = 10 finney;

	// Hard cap to protect the ETH network from a really high raise
	uint256 public hardCap = 1000000 ether;

	// minimum cap
	uint256 public minimumCap = 5000 ether;

	/* Contract Info */

	// the deposit address for the Eth that is raised.
	address public fundOwnerWallet;

	// owner the address of the contract depoloyer
	address public owner;

	// List of stage bonus percentages in every stage
	// this will get generated in the constructor
	uint[] public stageBonusPercentage;

	// total number of bonus stages.
	uint8 public totalStages;

	//  max bonus percentage on first stage
	uint8 public stageMaxBonusPercentage;

	// price of token per wei
	uint256 public tokenPrice;

	// the team owns 80% of the tokens - 4 times more than investors.
	uint8 public teamTokenRatio = 4;

	// gilgamesh token
	GilgameshToken public token;

	// if investment cap has been reached
	bool public isCapReached = false;

	// Contribution structor to store fund contributions
	struct Contribution {
		uint256 amount; // amount that investor has contributed
		address contributor; // address of the investor contributor
		uint256 blockNumber; // block number when the contribution occured
		uint256 userAssignedTokens; // number of tokens transferred to the user
	}

	// list of contributions
	Contribution[] contributions;

	// log when token sale has been initialized
	event LogTokenSaleInitialized(
		address owner,
		address fundOwnerWallet,
		uint256 startBlock,
		uint256 endBlock
	);

	// log each contribution
	event LogContribution(
		address contributorAddress,
		uint256 amount,
		uint256 totalRaised,
		uint256 userAssignedTokens
	);

	// log when crowd fund is finalized
	event LogFinalized(uint256 teamTokens);

	// Constructor
	function GilgameshTokenSale(
		uint256 _startBlock, // starting block number
		uint256 _endBlock, // ending block number
		address _fundOwnerWallet, // fund owner wallet address - transfer ether to this address after fund has been closed
		uint8 _totalStages, // total number of bonus stages
		uint8 _stageMaxBonusPercentage, // maximum percentage for bonus in the first stage
		uint256 _tokenPrice, // price of each token in wei
		address _gilgameshToken, // address of the gilgamesh ERC20 token contract
		uint256 _minimumCap // minimum cap, minimum amount of wei to be raised
	)
	validate_address(_fundOwnerWallet)
	validate_address(_gilgameshToken) {

		if (
			// start block needs to be in the future
			_startBlock < block.number ||
			// start block should be less than ending block
			_startBlock >= _endBlock ||
			// minimum number of stages
			_totalStages < 2 ||
			// verify stage max bonus
			_stageMaxBonusPercentage <= 0  ||
			// stage bonus percentage needs to be devisible by number of stages
			_stageMaxBonusPercentage % _totalStages != 0 ||
			// total number of blocks needs to be devisible by the total stages
			(_endBlock - _startBlock - 1) % _totalStages != 0
		) throw;

		owner = msg.sender;
		token = GilgameshToken(_gilgameshToken);
		endBlock = _endBlock;
		startBlock = _startBlock;
		fundOwnerWallet = _fundOwnerWallet;
		tokenPrice = _tokenPrice;
		totalStages = _totalStages;
		minimumCap = _minimumCap;
		stageMaxBonusPercentage = _stageMaxBonusPercentage;
		totalRaised = 0; //	total number of wei raised

		// spread bonuses evenly between stages - e.g 20 / 4 = 5%
		uint spread = stageMaxBonusPercentage / (totalStages - 1);

		// loop through [4 to 0] * 5% = [20%, 15%, 10%, 5%, 0%]
		for (uint stageNumber = totalStages - 1; stageNumber >= 0; stageNumber--) {
			stageBonusPercentage.push(stageNumber * spread);
		}

		LogTokenSaleInitialized(
			owner,
			fundOwnerWallet,
			startBlock,
			endBlock
		);
	}

	// --------------
	// Public Funtions
	// --------------

	/// @notice Function to stop sale for an emergency.
	/// @dev Only Gilgamesh Dev can do it after it has been activated.
	function emergencyStopSale()
	public
	only_sale_active
	onlyOwner {
		saleStopped = true;
	}

	/// @notice Function to restart stopped sale.
	/// @dev Only Gilgamesh Dev can do it after it has been disabled and sale is ongoing.
	function restartSale()
	public
	only_during_sale_period
	only_sale_stopped
	onlyOwner {
		saleStopped = false;
	}

	/// @notice Function to change the fund owner wallet address
	/// @dev Only Gilgamesh Dev can trigger this function
	function changeFundOwnerWalletAddress(address _fundOwnerWallet)
	public
	validate_address(_fundOwnerWallet)
	onlyOwner {
		fundOwnerWallet = _fundOwnerWallet;
	}

	/// @notice finalize the sale
	/// @dev Only Gilgamesh Dev can trigger this function
	function finalizeSale()
	public
	onlyOwner {
		doFinalizeSale();
	}

	/// @notice change hard cap and if it reaches hard cap finalize sale
	function changeCap(uint256 _cap)
	public
	onlyOwner {
		if (_cap >= hardCap) throw;
		if (_cap < minimumCap) throw;

		hardCap = _cap;

		if (totalRaised + minimumInvestment >= hardCap) {
			isCapReached = true;
			doFinalizeSale();
		}
	}

	/// @notice remove conttact only when sale has been finalized
	/// transfer all the fund to the contract owner
	/// @dev only Gilgamesh Dev can trigger this function
	function removeContract()
	public
	onlyOwner {
		if (!saleFinalized) throw;
		selfdestruct(msg.sender);
	}

	/// @notice only the owner is allowed to change the owner.
	/// @param _newOwner the address of the new owner
	function changeOwner(address _newOwner)
	onlyOwner {
		require(_newOwner != owner);
		owner = _newOwner;
	}

	/// @dev The fallback function is called when ether is sent to the contract, it
	/// simply calls deposit() with the address that sent the ether as the
	/// _owner.
	/// Payable is a required solidity modifier to receive ether
	/// every contract only has one unnamed function
	/// 2300 gas available for this function
	function () public payable {
		return deposit();
	}

	// --------------
	// Internal Funtions
	// --------------

	///	@dev deposit() is an internal function that sends the ether that this
	///	contract receives to the gilgameshFund and creates tokens in the address of the
	function deposit()
	public
	payable
	only_sale_active
	minimum_contribution()
	validate_address(msg.sender) {
		// if it passes hard cap throw
		if (totalRaised + msg.value > hardCap) throw;

		uint256 userAssignedTokens = calculateTokens(msg.value);

		// if user tokens are 0 throw
		if (userAssignedTokens <= 0) throw;

		// send funds to fund owner wallet
		if (!fundOwnerWallet.send(msg.value)) throw;

		// mint tokens for the user
		if (!token.mint(msg.sender, userAssignedTokens)) throw;

		// create a new contribution object
		contributions.push(
			Contribution({
				amount: msg.value,
				contributor: msg.sender,
				blockNumber: block.number,
				userAssignedTokens: userAssignedTokens
			})
		);

		// save total number wei raised
		totalRaised = safeAdd(totalRaised, msg.value);

		// if cap is reached mark it
		if (totalRaised >= hardCap) {
			isCapReached = true;
		}

		// log contribution event
		LogContribution(
			msg.sender,
			msg.value,
			totalRaised,
			userAssignedTokens
		);
	}

	/// @notice calculate number tokens need to be issued based on the amount received
	/// @param amount number of wei received
	function calculateTokens(uint256 amount)
	internal
	returns (uint256) {
		// return 0 if the crowd fund has ended or it hasn't started
		if (!isDuringSalePeriod(block.number)) return 0;

		// get the current stage number by block number
		uint8 currentStage = getStageByBlockNumber(block.number);

		// if current stage is more than the total stage return 0 - something is wrong
		if (currentStage > totalStages) return 0;

		// calculate number of tokens that needs to be issued for the investor
		uint256 purchasedTokens = safeDiv(amount, tokenPrice);
		// calculate number of tokens that needs to be rewraded to the investor
		uint256 rewardedTokens = calculateReward(purchasedTokens, currentStage);

		// add purchasedTokens and rewardedTokens
		return safeAdd(purchasedTokens, rewardedTokens);
	}

	/// @notice calculate reward based on amount of tokens that will be issued to the investor
	/// @param amount number tokens that will be minted for the investor
	/// @param stageNumber number of current stage in the crowd fund process
	function calculateReward(uint256 amount, uint8 stageNumber)
	internal
	returns (uint256 rewardAmount) {
		// throw if it's invalid stage number
		if (
			stageNumber < 1 ||
			stageNumber > totalStages
		) throw;

		// get stage index for the array
		uint8 stageIndex = stageNumber - 1;

		// calculate reward - e.q 100 token creates 100 * 20 /100 = 20 tokens for reward
		return safeDiv(safeMul(amount, stageBonusPercentage[stageIndex]), 100);
	}

	/// @notice get crowd fund stage by block number
	/// @param _blockNumber block number
	function getStageByBlockNumber(uint256 _blockNumber)
	internal
	returns (uint8) {
		// throw error, if block number is out of range
		if (!isDuringSalePeriod(_blockNumber)) throw;

		uint256 totalBlocks = safeSub(endBlock, startBlock);
		uint256 numOfBlockPassed = safeSub(_blockNumber, startBlock);

		// since numbers round down we need to add one to number of stage
		return uint8(safeDiv(safeMul(totalStages, numOfBlockPassed), totalBlocks) + 1);
	}

	/// @notice check if the block number is during the sale period
	/// @param _blockNumber block number
	function isDuringSalePeriod(uint256 _blockNumber)
	internal
	returns (bool) {
		return (_blockNumber >= startBlock && _blockNumber < endBlock);
	}

	/// @notice finalize the crowdfun sale
	/// @dev Only Gilgamesh Dev can trigger this function
	function doFinalizeSale()
	internal
	onlyOwner {
		// calculate the number of tokens that needs to be assigned to Gilgamesh team
		uint256 teamTokens = safeMul(token.totalSupply(), teamTokenRatio);

		// mint tokens for the team
		if (!token.mint(owner, teamTokens)) throw;

		// if there is any fund drain it
		if(this.balance > 0) {
			// send funds to fund owner wallet
			if (!fundOwnerWallet.send(this.balance)) throw;
		}

		// finalize sale flag
		saleFinalized = true;

		// stop sale flag
		saleStopped = true;

		// log finalized
		LogFinalized(teamTokens);
	}

	// --------------
	// Modifiers
	// --------------

	/// continue only when sale has stopped
	modifier only_sale_stopped {
		if (!saleStopped) throw;
		_;
	}


	/// validates an address - currently only checks that it isn't null
	modifier validate_address(address _address) {
		if (_address == 0x0) throw;
		_;
	}

	/// continue only during the sale period
	modifier only_during_sale_period {
		// if block number is less than starting block fail
		if (block.number < startBlock) throw;
		// if block number has reach to the end block fail
		if (block.number >= endBlock) throw;
		// otherwise safe to continue
		_;
	}

	/// continue when sale is active and valid
	modifier only_sale_active {
		// if sale is finalized fail
		if (saleFinalized) throw;
		// if sale is stopped fail
		if (saleStopped) throw;
		// if cap is reached
		if (isCapReached) throw;
		// if block number is less than starting block fail
		if (block.number < startBlock) throw;
		// if block number has reach to the end block fail
		if (block.number >= endBlock) throw;
		// otherwise safe to continue
		_;
	}

	/// continue if minimum contribution has reached
	modifier minimum_contribution() {
		if (msg.value < minimumInvestment) throw;
		_;
	}

	/// continue when the invoker is the owner
	modifier onlyOwner() {
		if (msg.sender != owner) throw;
		_;
	}
}
