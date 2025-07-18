// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.27;

import {ERC4626} from "solady/tokens/ERC4626.sol";
import {Ownable} from "solady/auth/Ownable.sol";
import {StrategyManager} from "./StrategyManager.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NexoraUSDCVault is ERC4626, Ownable, Pausable {
    using SafeERC20 for IERC20;

    address public strategyManager;
    address private immutable _asset;
    bool loopingWindowOver;
    uint256 public loopingWindow;
    IERC20 public usdc;

    // Track total USDC deposited and withdrawn
    uint256 public totalUSDCDeposited;
    uint256 public totalUSDCWithdrawn;

    event USDCDeposited(address indexed user, uint256 amount, uint256 shares);
    event USDCWithdrawn(address indexed user, uint256 amount, uint256 shares);
    event AllFundsWithdrawn(address indexed strategyManager, uint256 amount);

    modifier onlyStrategyManager() {
        require(msg.sender == strategyManager, "Only Strategy Manager");
        _;
    }

    modifier checkIfLoopingWindowOver() {
        require(loopingWindowOver, "Looping window not over");
        _;
    }

    constructor(address asset_, address _strategyManager, bool _loopingWindowOver, uint256 _loopingWindow) {
        _initializeOwner(msg.sender);
        _guardInitializeOwner();
        _asset = asset_;
        strategyManager = _strategyManager;
        loopingWindowOver = _loopingWindowOver;
        loopingWindow = _loopingWindow;
    }

    function name() public view virtual override returns (string memory) {
        return "Nexora USDC Vault";
    }

    function symbol() public view virtual override returns (string memory) {
        return "nxUSDC";
    }

    function asset() public view virtual override returns (address) {
        return _asset;
    }

    // Override decimals for USDC (6 decimals)
    function _underlyingDecimals() internal view virtual override returns (uint8) {
        return 6;
    }

    // User  functions
    function deposit(uint256 assets, address to) public virtual override whenNotPaused returns (uint256 shares) {
        shares = super.deposit(assets, to);
        totalUSDCDeposited += assets;
        emit USDCDeposited(msg.sender, assets, shares);
    }

    function withdraw(uint256 assets, address to, address owner)
        public
        virtual
        override
        whenNotPaused
        returns (uint256 shares)
    {
        shares = super.withdraw(assets, to, owner);
        totalUSDCWithdrawn += assets;
        emit USDCWithdrawn(owner, assets, shares);
    }

    function previewDeposit(uint256 assets) public view virtual override returns (uint256 shares) {
        return super.previewDeposit(assets);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256 shares) {
        return super.previewWithdraw(assets);
    }

    function previewMint(uint256 shares) public view virtual override returns (uint256 assets) {
        return super.previewMint(shares);
    }

    function previewRedeem(uint256 shares) public view virtual override returns (uint256 assets) {
        return super.previewRedeem(shares);
    }

    // Strategy Manager functions
    function withdrawAllFunds() public onlyStrategyManager whenPaused {
        uint256 vaultBalance = IERC20(_asset).balanceOf(address(this));
        require(vaultBalance > 0, "No funds to withdraw");
        IERC20(_asset).safeTransfer(strategyManager, vaultBalance);
        emit AllFundsWithdrawn(strategyManager, vaultBalance);
    }

    // Owner functions
    function setLoopingWindow(uint256 _loopingWindow) public onlyOwner {
        loopingWindow = _loopingWindow;
    }

    function toggleLoopingPeriod(bool isLoopingOver) public onlyOwner {
        loopingWindowOver = isLoopingOver;
    }

    // Pause/Unpaused
    function pause() public onlyOwner {
        super._pause();
    }

    function unpause() public onlyOwner {
        super._unpause();
    }
}
