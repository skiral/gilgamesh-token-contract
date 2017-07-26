pragma solidity ^0.4.11;

import "./ERC20TokenInterface.sol";

/*
	Copyright 2017, Skiral Inc
*/

contract ERC20Token is ERC20TokenInterface {

	// State variables
	mapping (address => uint256) public balanceOf;
	string public name;		// The Token's name: e.g. Gilgamesh Tokens
	string public symbol;
	uint8 public decimal;	// Number of decimals of the smallest unit
	uint256 public totalSupply;

	function ERC20Token(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol,
		uint8 decimalUnits
	) {
		// assign all tokens to the deployer
		balanceOf[msg.sender] = initialSupply;

		totalSupply =  initialSupply;
		decimal = decimalUnits;
		symbol = tokenSymbol;
		name = tokenName;
	}

	//--------------
	// ERC20 Methods
	//--------------
	function transfer(address _to, uint _value) returns (bool success) {
		// if sender has enough token
		if (balanceOf[msg.sender] < _value) throw;

		// preventing overflow on the "to" account
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;

		// subtract tokens from the sender
		balanceOf[msg.sender] -= _value;

		// add tokens to the receiver
		balanceOf[_to] += _value;

		Transfer(msg.sender, _to, _value);
		return true;
	}
}
