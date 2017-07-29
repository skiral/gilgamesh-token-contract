pragma solidity ^0.4.11;

contract SafeMath {

	function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeSub(uint256 a, uint256 b) internal returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function safeMul(uint256 a, uint256 b) internal returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
		assert(b > 0);
		uint256 c = a / b;
		assert(a == b * c + a % b);
		return c;
	}
}
