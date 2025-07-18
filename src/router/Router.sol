// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Ownable} from "solady/auth/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Interface for making arbitrary calls during swap
interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable returns (uint256); // 0x4b64e492
}

/// @title Interface for 1Inch Generic Router
interface IGenericRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    function swap(IAggregationExecutor executor, SwapDescription calldata desc, bytes calldata data)
        external
        payable
        returns (uint256 returnAmount, uint256 spentAmount);
}

contract Router is Ownable {
    using SafeERC20 for IERC20;

    address public GENERIC_ROUTER;
    address public  srcToken;
    address public dstToken;

    constructor(address _router, address _srcToken,address _dstToken) {
        GENERIC_ROUTER = _router;
        srcToken = _srcToken;
        dstToken = _dstToken;
    }

    function setGenericRouter(address _router) external onlyOwner {
        GENERIC_ROUTER = _router;
    }

    function performSwap(address executor, IGenericRouter.SwapDescription calldata desc, bytes calldata data)
        external returns(uint256 returnAmount,uint256 spentAmount)
    {
        IERC20(desc.srcToken).safeTransferFrom(msg.sender, address(this), desc.amount);
        IERC20(desc.srcToken).forceApprove(GENERIC_ROUTER, desc.amount);

        (bool success, bytes memory result) =
            GENERIC_ROUTER.call(abi.encodeWithSelector(IGenericRouter.swap.selector, executor, desc, data));

        require(success, "Swap via GenericRouter failed");

        (returnAmount,spentAmount) = abi.decode(result, (uint256, uint256));
    }
}
