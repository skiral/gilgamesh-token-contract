/*
	Copyright 2017, Skiral Inc
*/
pragma solidity ^0.4.11;

import "./SecureERC20Token.sol";

contract GilgameshToken is SecureERC20Token {
	// @notice Constructor to create Gilgamesh ERC20 Token
	function GilgameshToken()
	SecureERC20Token(
		0, // no token in the begning
		"Gilgamesh Token", // Token Name
		"GIL", // Token Symbol
		18, // Decimals
		true // Enable token transfer
	) {}

}
