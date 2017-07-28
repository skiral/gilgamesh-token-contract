pragma solidity 0.4.11;

import "./ERC20Token.sol";
import "./Admin.sol";

/*
	Copyright 2017, Skiral Inc
*/
contract SecureERC20Token is Admin, ERC20Token {

	// State variables

	// `balances` dictionary that maps addresses to balances
	mapping (address => uint256) private balances;

	 // `allowed` dictionary that allow transfer rights to other addresses.
	mapping (address => mapping(address => uint256)) private allowed;

	// The Token's name: e.g. 'Gilgamesh Tokens'
	string public name;

	// Symbol of the token: e.q 'GIL'
	string public symbol;

	// Number of decimals of the smallest unit: e.g '18'
	uint8 public decimals;

	// Number of total tokens: e,g: '1000000000'
	uint256 public totalSupply;

	// token version
	uint8 public version = 1;

	// address of the contract admin
	address public admin;

	// `creationBlock` is the block number that the Token was created
    uint public creationBlock;

	// Flag that determines if the token is transferable or not
	// disable actionable ERC20 token methods
	bool public isTransferEnabled;

	// @notice Constructor to create Gilgamesh ERC20 Token
	function SecureERC20Token(
		uint256 initialSupply,
		string _name,
		string _symbol,
		uint8 _decimals,
		bool _isTransferEnabled
	) {
		// assign all tokens to the deployer
		balances[msg.sender] = initialSupply;

		totalSupply = initialSupply; // set initial supply of Tokens
		name = _name;				 // set token name
		decimals = _decimals;		 // set the decimals
		symbol = _symbol;			 // set the token symbol
		isTransferEnabled = _isTransferEnabled;
		creationBlock = block.number;
		minter = msg.sender;		// by default the contract deployer is the minter
		admin = msg.sender;			// by default the contract deployer is the admin
	}

	// --------------
	// ERC20 Methods
	// --------------

	/// @notice Get the total amount of token supply
	function totalSupply() constant returns (uint256 totalSupply) {
		return totalSupply;
	}

	/// @notice Get the account balance of address `_owner`
	/// @param `_owner` The address from which the balance will be retrieved
	/// @return The balance
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	/// @notice send `_value` amount of tokens to `_to` address from `msg.sender` address
	/// @param `_to` The address of the recipient
	/// @param `_value` The amount of token to be transferred
	/// @return a boolean - whether the transfer was successful or not
	function transfer(address _to, uint256 _value) returns (bool success) {
		// if transfer is not enabled throw an error and stop execution.
		require(isTransferEnabled);

		// continue with transfer
		return doTransfer(msg.sender, _to, _value);
	}

	/// @notice send `_value` amount of tokens to `_to` address from `_from` address, on the condition it is approved by `_from`
	/// @param `_from` The address of the sender
	/// @param `_to` The address of the recipient
	/// @param `_value` The amount of token to be transferred
	/// @return a boolean - whether the transfer was successful or not
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		// if transfer is not enabled throw an error and stop execution.
		require(isTransferEnabled);

		// if `from` allowed transferrable rights to `sender` for amount `_value`
		if (allowed[_from][msg.sender] < _value) throw;

		// subtreact allowance
		allowed[_from][msg.sender] -= _amount;

		// continue with transfer
		return doTransfer(_from, _to, _value);
	}

	/// @notice `msg.sender` approves `_spender` to spend `_value` tokens
	/// @param `_spender` The address of the account able to transfer the tokens
	/// @param `_value` The amount of tokens to be approved for transfer
	/// @return a boolean - whether the approval was successful or not
	function approve(address _spender, uint256 _value) returns (bool success) {
		// if transfer is not enabled throw an error and stop execution.
		require(isTransferEnabled);

		// user can only reassign an allowance of `0` if value is greater than `0`
		// sender should first change the allowance to zero by calling `approve(_spender, 0)`
		// race condition is explained below:
		// https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
		if(_value != 0 && allowed[msg.sender][_spender] != 0) throw;

		if (
			// if sender balance is less than `_value` return false;
			balances[msg.sender] < _value
		) {
			// transaction failure
			return false;
		}

		// allow transfer rights from `msg.sender` to `_spender` for `_value` token amount
		allowed[msg.sender][_spender] = _value;

		// log approval event
		Approval(msg.sender, _spender, _value);

		// transaction successful
		return true;
	}

	/// @param `_owner` The address of the account owning tokens
	/// @param `_spender` The address of the account able to transfer the tokens
	/// @return Amount of remaining tokens allowed to spent by the `_spender` from `_owner` account
	function allowance(address _owner, address _spender)
	constant
	returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	// --------------
	// Contract Custom Methods - Non ERC20
	// --------------

	/* Public Methods */

	/// @notice only the admin is allowed to change the minter.
	/// @param `_minter` the address of the minter
	function changeMinter(address _minter) onlyAdmin {
		minter = _minter;
	}

	/// @notice mint new tokens by the minter
	/// @
	function mint(address _owner, uint256 _amount)
	onlyMinter
	returns (bool success) {
		// preventing overflow on the `totalSupply`
		if (totalSupply + _amount < totalSupply) throw;

		// preventing overflow on the receiver account
		if (balances[_owner] + _amount < balances[_owner]) throw;

		// increase the total supply
		totalSupply +=  _amount;

		// assign the additional supply to the target account.
		balances[_owner] += _amount;

		// contract has transfered token to the target account
		Transfer(this, _owner, _amount);
	}

	/// @notice Enables token holders to transfer their tokens freely if true
	/// after the crowdsale is finished it will be true
	/// for security reasons can be switched to false
	/// @param _isTransferEnabled boolean
	function enableTransfers(bool _isTransferEnabled) onlyAdmin {
		isTransferEnabled = _isTransferEnabled;
	}

	/* Internal Methods */

	///	@dev this is the actual transfer function and it can only be called internally
	/// @notice send `_value` amount of tokens to `_to` address from `_from` address
	/// @param `_to` The address of the recipient
	/// @param `_value` The amount of token to be transferred
	/// @return a boolean - whether the transfer was successful or not
	function doTransfer(address _from, address _to, uint256 value)
	internal
	returns (bool success) {
		if (
			// if the value is not more than 0 fail
			_value <= 0 ||
			// if the sender doesn't have enough balance fail
			balances[msg.sender] < _value ||
			// if token supply overflows (total supply exceeds 2^256 - 1) fail
			balances[_to] + _value < balances[_to]
		) {
			// transaction failed
			return false;
		}

		// decrease the number of tokens from `sender` address.
		balances[msg.sender] -= _value;

		// increase the number of tokens for `_to` address
		balances[_to] += _value;

		// log transfer event
		Transfer(msg.sender, _to, _value);

		// transaction successful
		return true;
	}

	modifier onlyMinter() {
		// if sender is not the minter stop the execution
		if (msg.sender != minter) throw;
		// if the sender is the minter continue
		_;
	}
}
