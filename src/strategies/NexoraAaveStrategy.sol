// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "solady/auth/Ownable.sol";
import {StrategyManager} from "src/StrategyManager.sol";
import {NexoraUSDCVault} from "src/NexoraUSDCVault.sol";

contract NexoraAaveStrategy is Ownable {
    address strategyManager;
    StrategyManager strategy;
    NexoraUSDCVault vault;

    constructor(address _strategy, address _vault) {
        _initializeOwner(msg.sender);
        _guardInitializeOwner();
        strategyManager = msg.sender;
        vault = NexoraUSDCVault(_vault);
        strategy = StrategyManager(_strategy);
    }

    function depositToAaveStrategy() public onlyOwner {}
}
