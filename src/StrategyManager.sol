// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "solady/auth/Ownable.sol";
import {NexoraUSDCVault} from "src/NexoraUSDCVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract StrategyManager is Ownable {
    NexoraUSDCVault vault;
    
    event AllFundsWithdrawn(address, uint256);

    using SafeERC20 for IERC20;

    constructor(address _vault) {
        _initializeOwner(msg.sender);
        _guardInitializeOwner();
        vault = NexoraUSDCVault(_vault);
    }

    function withdrawFromVault() public onlyOwner {
        vault.withdrawAllFunds();
    }

    function depositToStrategies(address _asset, address _strategy) public onlyOwner {
        uint256 contractBalance = IERC20(_asset).balanceOf(address(this));
        require(contractBalance > 0, "No funds to withdraw");
        IERC20(_asset).safeTransfer(_strategy, contractBalance);
        emit AllFundsWithdrawn(msg.sender, contractBalance);
    }
}
