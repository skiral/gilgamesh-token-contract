/*
	Copyright 2017, Skiral Inc
*/
pragma solidity 0.4.11;

import "./SecureERC20Token.sol";

contract GilgameshToken is SecureERC20Token {
	// @notice Constructor to create Gilgamesh ERC20 Token
	function GilgameshToken()
	SecureERC20Token(
		10 ** 9, 			// 1 billion token reserved for team, gilgamesh users, marketing, legal...
		"Gilgamesh Token",	// Token Name
		"GIL",				// Token Symbol
		18,					// Decimals
		true				// Enable token transfer
	) {}

}
