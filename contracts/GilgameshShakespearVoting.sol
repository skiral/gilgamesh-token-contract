pragma solidity ^0.4.13;

contract GilgameshShakespeareVoting {

    /// mapping addresses to proposalIds.
    /// each address can only vote to one Id.
    mapping(address => int256) public votes;

    /// voters array - used to assist for iteration
    address[] public voters;

    uint256 public endBlock;

	// address of the contract admin
	address public admin;

    event onVote(address indexed voter, int256 indexed proposalId);
    event onUnVote(address indexed voter, int256 indexed proposalId);

    function GilgameshShakespeareVoting(uint256 _endBlock) {
        endBlock = _endBlock;
		admin = msg.sender;
    }

	function changeEndBlock(uint256 _endBlock)
	onlyAdmin {
		endBlock = _endBlock;
	}

    function vote(int256 proposalId) {

        // validate sender address
        require(msg.sender != address(0));

        // if proposalId is  <= 0 reject the transaction
        require(proposalId > 0);

        // continue if we haven't reached to the end block
        require(endBlock == 0 || block.number <= endBlock);

        // if voters hasn't voted before, push the voter to the list of voters
        if (votes[msg.sender] == 0) {
            voters.push(msg.sender);
        }

        // register vote for a proposal id
        votes[msg.sender] = proposalId;

        // fire an event
        onVote(msg.sender, proposalId);
    }

    function unVote() {
        // validate sender address
        require(msg.sender != address(0));

        // unvote only if the users has voted on a proposal id.
        require(votes[msg.sender] > 0);

        int256 proposalId = votes[msg.sender];

		// unregister vote
		votes[msg.sender] = -1;

        // fire an event
        onUnVote(msg.sender, proposalId);
    }

    function votersCount()
    constant
    returns(uint256) {
        return voters.length;
    }

    function getVoters(uint256 offset, uint256 limit)
    constant
    returns(address[] _voters, int256[] _proposalIds) {

        if (offset < voters.length) {
            uint256 resultLength = limit;
            uint256 index = 0;

            // make sure the limit doesn't exceed the size of the array
            if (voters.length - offset < limit) {
                resultLength = voters.length - offset;
            }

            _voters = new address[](resultLength);
            _proposalIds = new int256[](resultLength);

            for(uint256 i = offset; i < offset + resultLength; i++) {
                _voters[index] = voters[i];
                _proposalIds[index] = votes[voters[i]];
                index++;
            }

            return (_voters, _proposalIds);
        }
    }

	modifier onlyAdmin() {
		// if sender is not the admin stop the execution
		if (msg.sender != admin) revert();
		// if the sender is the admin continue
		_;
	}
}
