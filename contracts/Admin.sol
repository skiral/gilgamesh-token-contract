pragma solidity 0.4.11;

/*
	Copyright 2017, Skiral Inc
*/
contract Admin {
	address public admin;

	function Admin() {
		// assign contract deployer as an admin
		admin = msg.sender;
	}

	modifier onlyAdmin() {
		// if sender is not the admin stop the execution
		if (msg.sender != admin) throw;
		// if the sender is the admin continue
		_;
	}

	function changeAdmin(address newAdmin) onlyAdmin {
		admin = newAdmin;
	}
}
