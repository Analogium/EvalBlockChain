// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/VoteSystem.sol";
import "../script/VoteSystem.s.sol";

contract VoteSystemTest is Test {
    VoteSystem public voteSystem;
    address public admin = address(1);
    address public voter1 = address(2);
    address public voter2 = address(3);
    address public founder = address(4);

    function setUp() public {
        voteSystem = new VoteSystem();
        voteSystem.grantRole(voteSystem.ADMIN_ROLE(), admin);
        voteSystem.grantRole(voteSystem.FOUNDER_ROLE(), founder);
    }

    function testAddCandidate() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Bruno");
        VoteSystem.Candidate memory candidate = voteSystem.getCandidate(1);
        assertEq(candidate.name, "Bruno");
        assertEq(candidate.voteCount, 0);
        vm.stopPrank();
    }

    function testVote() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Bob");
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        voteSystem.startVote();
        vm.stopPrank();

        vm.startPrank(voter1);
        voteSystem.vote(1);
        uint voteCount = voteSystem.getTotalVotes(1);
        assertEq(voteCount, 1);
        vm.stopPrank();
    }

    function testDoubleVoting() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Charlie");
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        voteSystem.startVote();
        vm.stopPrank();

        vm.startPrank(voter1);
        voteSystem.vote(1);
        vm.expectRevert("You have already voted");
        voteSystem.vote(1);
        vm.stopPrank();
    }

    function testVoteWithinOneHour() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Charlie");
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        voteSystem.startVote();
        vm.stopPrank();

        vm.startPrank(voter1);
        voteSystem.vote(1);
        uint voteCount = voteSystem.getTotalVotes(1);
        assertEq(voteCount, 1);
        vm.stopPrank();


        vm.warp(block.timestamp + 30 minutes);

        vm.startPrank(voter2);
        voteSystem.vote(1);
        voteCount = voteSystem.getTotalVotes(1);
        assertEq(voteCount, 2);
        vm.stopPrank();
    }

    function testVoteAfterOneHour() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Dana");
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        voteSystem.startVote();
        vm.stopPrank();

        vm.warp(block.timestamp + 1 hours + 1);

        vm.startPrank(voter1);
        vm.expectRevert("Voting period has ended");
        voteSystem.vote(1);
        vm.stopPrank();
    }


    function testInvalidCandidateId() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        voteSystem.startVote();
        vm.stopPrank();

        vm.startPrank(voter1);
        vm.expectRevert("Invalid candidate ID");
        voteSystem.vote(999);
        vm.stopPrank();
    }

    function testSetWorkflowStatus() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        assertEq(uint(voteSystem.workflowStatus()), uint(VoteSystem.WorkflowStatus.VOTE));
        vm.stopPrank();
    }

    function testFundCandidate() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Dana");
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.FOUND_CANDIDATES);
        vm.stopPrank();

        vm.deal(founder, 1 ether);
        vm.startPrank(founder);
        voteSystem.fundCandidate{value: 1 ether}(1);
        VoteSystem.Candidate memory candidate = voteSystem.getCandidate(1);
        assertEq(candidate.voteCount, 1 ether);
        vm.stopPrank();
    }

    function testDetermineWinner() public {
        vm.startPrank(admin);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.REGISTER_CANDIDATES);
        voteSystem.addCandidate("Alice");
        voteSystem.addCandidate("Bob");
        voteSystem.addCandidate("Charlie");
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.VOTE);
        voteSystem.startVote();
        vm.stopPrank();

        vm.startPrank(voter1);
        voteSystem.vote(1); // voter1 vote pour Alice
        vm.stopPrank();

        vm.startPrank(voter2);
        voteSystem.vote(2); // voter2 vote pour Bob
        vm.stopPrank();

        address voter3 = address(5);
        address voter4 = address(6);
        address voter5 = address(7);

        vm.startPrank(voter3);
        voteSystem.vote(1); // voter3 vote pour Alice
        vm.stopPrank();

        vm.startPrank(voter4);
        voteSystem.vote(2); // voter4 vote pour Bob
        vm.stopPrank();

        vm.startPrank(voter5);
        voteSystem.vote(2); // voter5 vote pour Bob
        vm.stopPrank();

        vm.startPrank(admin);
        vm.warp(block.timestamp + 1 hours + 1);
        voteSystem.setWorkflowStatus(VoteSystem.WorkflowStatus.COMPLETED);
        VoteSystem.Candidate memory winner = voteSystem.determineWinner();
        assertEq(winner.name, "Bob"); // Bob devrait gagner
        assertEq(winner.voteCount, 3);
        vm.stopPrank();
    }

}
