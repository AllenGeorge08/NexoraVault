// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "solady/auth/Ownable.sol";
import {NexoraUSDCVault} from "src/NexoraUSDCVault.sol";

contract StrategyManager is Ownable {

    NexoraUSDCVault vault;

    constructor(address _vault) {
        _initializeOwner(msg.sender);
        _guardInitializeOwner();
        vault = NexoraUSDCVault(_vault);
    }

    function withdrawFromVault() public onlyOwner(){
        vault.withdrawAllFunds();
    }
}
