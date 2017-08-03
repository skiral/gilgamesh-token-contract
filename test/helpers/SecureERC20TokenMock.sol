/*
	Copyright 2017, Skiral Inc
*/
pragma solidity ^0.4.11;

import "../../contracts/SecureERC20Token.sol";

contract SecureERC20TokenMock is SecureERC20Token {
	// @notice Constructor to create Gilgamesh ERC20 Token
	function SecureERC20TokenMock(
		uint256 initialSupply,
		string _name,
		string _symbol,
		uint8 _decimals,
		bool _isTransferEnabled
	)
	SecureERC20Token(
		initialSupply,
		_name,
		_symbol,
		_decimals,
		_isTransferEnabled
	) {}

}
