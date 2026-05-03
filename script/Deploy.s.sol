// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {AgentRegistry} from "../src/AgentRegistry.sol";
import {ReputationOracle} from "../src/ReputationOracle.sol";
import {GameArchive} from "../src/GameArchive.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address gameMaster = vm.envOr("GM_ADDRESS", vm.addr(deployerPk));

        vm.startBroadcast(deployerPk);

        AgentRegistry registry = new AgentRegistry();
        ReputationOracle reputation = new ReputationOracle(gameMaster);
        GameArchive archive = new GameArchive(gameMaster);

        vm.stopBroadcast();

        console2.log("=== Agent Werewolf Deployment ===");
        console2.log("Chain ID:        ", block.chainid);
        console2.log("Deployer:        ", vm.addr(deployerPk));
        console2.log("GameMaster:      ", gameMaster);
        console2.log("AgentRegistry:   ", address(registry));
        console2.log("ReputationOracle:", address(reputation));
        console2.log("GameArchive:     ", address(archive));

        // Write deployments to JSON
        string memory json = string.concat(
            "{\n",
            '  "chainId": ', vm.toString(block.chainid), ",\n",
            '  "AgentRegistry": "', vm.toString(address(registry)), '",\n',
            '  "ReputationOracle": "', vm.toString(address(reputation)), '",\n',
            '  "GameArchive": "', vm.toString(address(archive)), '",\n',
            '  "GameMaster": "', vm.toString(gameMaster), '",\n',
            '  "deployedAt": ', vm.toString(block.timestamp), "\n",
            "}"
        );
        vm.writeFile("./deployments/galileo.json", json);
    }
}
