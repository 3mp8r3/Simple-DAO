pragma solidity ^0.5.2;

/**
 * DAO contract:
 * 1. Collects investors money (ether) & allocate shares
 * 2. Keep track of investor contributions with shares
 * 3. Allow investors to transfer shares
 * 4. allow investment proposals to be created and voted
 * 5. execute successful investment proposals (i.e send money)
 */

 contract DAO {

     struct Proposal {
         uint id;
         string name;
         uint amount;
         address payable recipient;
         uint votes;
         uint end;
         bool executed;
     }
     
     mapping(address => bool) public investors;
     mapping(address => uint) public shares;
     mapping(uint => Proposal) public proposals;
     mapping(address => mapping(uint => bool)) public votes;

     
     uint public totalShares;
     uint public availableFunds;
     uint public public contributionEnd;
     uint public nextProposalId;
     uint public voteTime;
     uint public quorum;
     address public admin;

     constructor (uint contributionTime) public {
         contributionEnd = now + contributionTime;
     }

    function contribute() payable external {
        require(now < contributionEnd, "cannot contribute after contribution period ended");
        investors[msg.sender] = true;
        shares[msg.sender] += msg.value;
        totalShares += msg.value;
        availableFunds += msg.value;
    }

    function redeemShare(uint amount) external {
        require(shares[msg.sender] >= amount, "not enough shares");
        require(availableFunds >= amount, 'not enough available in funds');
        // require(investors[msg.sender] = true, "not an investor");
        shares[msg.sender] -= amount;
        availableFunds -= amount;
        msg.sender.transfer(amount);
    }

    function transferShare(uint amount, address to) external {
        require(shares[msg.sender] >= amount, "not enough shares");
        shares[msg.sender] -= amount;
        shares[to] += amount;
        investors[to] = true;
    }

    function createProposal(
        string memory name,
        uint amount,
        address payable recipient
    ) external {
        require(availableFunds >= amount, 'amount too big');
        proposals[nextProposalId] = Proposal(
            nextProposalId,
            name,
            amount,
            recipient,
            0,
            now + voteTime,
            false
        );
        availableFunds -= amount;
        nextProposalId++;
    }

    function vote(uint proposalId) onlyInvestors() {
        Proposal storage proposal = proposals[proposalId];
        require(votes[msg.sender][proposalId] == false, 'investor can only vote once for a proposal');
        require(now < proposal.end, 'can only vote until proposal end');
        votes[msg.sender][proposalId] == true;
        proposal.votes += shares[msg.sender];
    }

    function executeProposal(uint proposalId) external onlyAdmin {
        Proposal storage proposal = proposals[proposalId];
        require(now >= proposal.end, "cannot execute a proposal before end date");
        require(proposal.executed == false, 'cannot execute a proposal already executed');
        require((proposal.votes / totalShares) * 100 >= quorum, "cannot execute a proposal with votes below quorum")
        _transferEther(proposal.amount, proposal.recipient);
    }

    function withdrawEther(uint amount, address payable to) external onlyAdmin() {
        _transferEther(amount, to);
    }

    function() payable external {
        availableFunds += msg.value;
    }

    function _transferEther(uint amount, address payable to) internal {
        require(amount <= avaiableFunds, 'not enough available funds');
        availableFunds -= amount;
        to.transfer(amount);
    }

    modifier onlyInvestors() {
        require(investors[msg.sender] == true, 'only investors');
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }
 }