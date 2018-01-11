/*
	Copyright 2017, Skiral Inc
*/
pragma solidity ^0.4.18;

import "../../contracts/GilgameshTokenSale.sol";

contract GilgameshTokenSaleMock is GilgameshTokenSale {
	// @notice Constructor to create Gilgamesh ERC20 Token
	function GilgameshTokenSaleMock(
		uint256 _startBlock, // starting block number
		uint256 _endBlock, // ending block number
		address _fundOwnerWallet, // fund owner wallet address - transfer ether to this address after fund has been closed
		address _tokenOwnerWallet, // token fund owner wallet address - transfer GIL tokesn to this address after fund is finalized
		uint8 _totalStages, // total number of bonus stages
		uint8 _stageMaxBonusPercentage, // maximum percentage for bonus in the first stage
		uint256 _tokenPrice, // price of each token in wei
		address _gilgameshToken, // address of the gilgamesh ERC20 token contract
		uint256 _minimumCap, // minimum cap, minimum amount of wei to be raised
		uint256 _blockNumber, // current block number
		uint256 _tokenCap // tokenCap

	)
	public
	GilgameshTokenSale(
		_startBlock,
		_endBlock,
		_fundOwnerWallet,
		_tokenOwnerWallet,
		_totalStages,
		_stageMaxBonusPercentage,
		_tokenPrice,
		_gilgameshToken,
		_minimumCap,
		_tokenCap
	) {
		// in case we want to override the block number
		if (_blockNumber != 1) {
			mock_blockNumber = _blockNumber;
		}
	}

	uint256 public mock_blockNumber = 1;

	// override the block number
	function getBlockNumber() internal constant returns (uint) {
		return mock_blockNumber;
	}

	function setMockedBlockNumber(uint b) public {
		mock_blockNumber = b;
	}

	// mock internal methods
	function isDuringSalePeriodMock(uint256 _blockNumber) public view returns (bool) {
		return isDuringSalePeriod(_blockNumber);
	}

	function getStageByBlockNumberMock(uint256 _blockNumber) public view returns (uint8) {
		return getStageByBlockNumber(_blockNumber);
	}

	function calculateTokensMock(uint256 amount) public view returns (uint256) {
		return calculateTokens(amount);
	}

	function calculateRewardTokensMock(uint256 amount, uint8 stageNumber)
	view
	public
	returns (uint256 rewardAmount) {
		return calculateRewardTokens(amount, stageNumber);
	}

	function setTotalRaised(uint256 amount)
	public {
		totalRaised = amount;
	}

	function setCapHasReached(bool _isCapReached) public {
		isCapReached = _isCapReached;
	}
}
