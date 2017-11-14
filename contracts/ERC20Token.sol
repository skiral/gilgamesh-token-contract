/*
	Copyright 2017, Skiral Inc
*/

// https://github.com/ethereum/EIPs/issues/20

// ERC20 compliant token interface
// Wallets and Exchanges can easily use a ERC20 compliant token.
pragma solidity ^0.4.18;

contract ERC20Token {

	// --------
	//	Events
	// ---------

	// publicize actions to external listeners.
	/// @notice Triggered when tokens are transferred.
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	/// @notice Triggered whenever approve(address _spender, uint256 _value) is called.
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	// --------
	//	Getters
	// ---------

	/// @notice Get the total amount of token supply
	function totalSupply() public constant returns (uint256 _totalSupply);

	/// @notice Get the account balance of address _owner
	/// @param _owner The address from which the balance will be retrieved
	/// @return The balance
	function balanceOf(address _owner) public constant returns (uint256 balance);

	/// @param _owner The address of the account owning tokens
	/// @param _spender The address of the account able to transfer the tokens
	/// @return Amount of remaining tokens allowed to spent by the _spender from _owner account
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

	// --------
	//	Actions
	// ---------

	/// @notice send _value amount of tokens to _to address from msg.sender address
	/// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
	/// @return a boolean - whether the transfer was successful or not
	function transfer(address _to, uint256 _value) public returns (bool success);

	/// @notice send _value amount of tokens to _to address from _from address, on the condition it is approved by _from
	/// @param _from The address of the sender
	/// @param _to The address of the recipient
	/// @param _value The amount of token to be transferred
	/// @return a boolean - whether the transfer was successful or not
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	/// @notice msg.sender approves _spender to spend multiple times up to _value amount of tokens
	/// If this function is called again it overwrites the current allowance with _value.
	/// @param _spender The address of the account able to transfer the tokens
	/// @param _value The amount of tokens to be approved for transfer
	/// @return a boolean - whether the approval was successful or not
	function approve(address _spender, uint256 _value) public returns (bool success);
}
