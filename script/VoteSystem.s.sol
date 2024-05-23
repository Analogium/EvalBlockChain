// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/VoteSystem.sol";

contract DeployVoteSystem is Script {
    function run() external returns (VoteSystem) {
        address admin = msg.sender;
        vm.startBroadcast();
        VoteSystem voteSystem = new VoteSystem();
        voteSystem.grantRole(voteSystem.ADMIN_ROLE(), admin); // j'ai beau grant le role, je n'arrive pas à l'utiliser dans le fichier de test
        vm.stopBroadcast();
        return voteSystem;
    }
}
