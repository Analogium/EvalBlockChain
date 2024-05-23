// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract VoteSystem is AccessControl {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint[] private candidateIds;

    enum WorkflowStatus { REGISTER_CANDIDATES, FOUND_CANDIDATES, VOTE, COMPLETED }
    WorkflowStatus public workflowStatus;

    uint public voteStartTime;
    uint constant VOTE_DURATION = 1 hours;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Only admin can do this action");
        _;
    }

    modifier inWorkflowStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "Function cannot be called at this time");
        _;
    }

    function addCandidate(string memory _name) public onlyAdmin inWorkflowStatus(WorkflowStatus.REGISTER_CANDIDATES) {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        uint candidateId = candidateIds.length + 1;
        candidates[candidateId] = Candidate(candidateId, _name, 0);
        candidateIds.push(candidateId);
    }

    function startVote() public onlyAdmin {
        setWorkflowStatus(WorkflowStatus.VOTE);
        voteStartTime = block.timestamp;
    }

    function vote(uint _candidateId) public inWorkflowStatus(WorkflowStatus.VOTE) {
        require(block.timestamp <= voteStartTime + VOTE_DURATION, "Voting period has ended");
        require(!voters[msg.sender], "You have already voted");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount += 1;
    }

    function getTotalVotes(uint _candidateId) public view returns (uint) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId].voteCount;
    }

    function getCandidatesCount() public view returns (uint) {
        return candidateIds.length;
    }

    function getCandidate(uint _candidateId) public view returns (Candidate memory) {
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");
        return candidates[_candidateId];
    }

    function setWorkflowStatus(WorkflowStatus _status) public onlyAdmin {
        workflowStatus = _status;
    }

    function fundCandidate(uint _candidateId) public payable {
        require(hasRole(FOUNDER_ROLE, msg.sender), "Only founders can fund candidates");
        require(_candidateId > 0 && _candidateId <= candidateIds.length, "Invalid candidate ID");

        candidates[_candidateId].voteCount += msg.value;
    }

    function determineWinner() public view inWorkflowStatus(WorkflowStatus.COMPLETED) returns (Candidate memory) {
        uint winningVoteCount = 0;
        Candidate memory winningCandidate;

        for (uint i = 0; i < candidateIds.length; i++) {
            if (candidates[candidateIds[i]].voteCount > winningVoteCount) {
                winningVoteCount = candidates[candidateIds[i]].voteCount;
                winningCandidate = candidates[candidateIds[i]];
            }
        }

        return winningCandidate;
    }
}
