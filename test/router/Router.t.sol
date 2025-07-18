// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {Test,console} from "forge-std/Test.sol";
import {Router} from "src/router/Router.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGenericRouter} from "src/router/Router.sol";


contract MockERC20 is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function transfer(address to, uint256 amount) public override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient");
        require(allowance[from][msg.sender] >= amount, "Not allowed");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(balanceOf[from] >= amount, "Insufficient");
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}

contract Mock1InchRouter {
    event SwapCalled(address executor, address srcToken, address dstToken, address srcReceiver, address dstReceiver, uint256 amount, uint256 minReturnAmount, uint256 flags, bytes data);
    uint256 public returnAmount;
    uint256 public spentAmount;
    bool public shouldRevert;

    function setReturn(uint256 _return, uint256 _spent) external {
        returnAmount = _return;
        spentAmount = _spent;
    }
    function setRevert(bool _shouldRevert) external {
        shouldRevert = _shouldRevert;
    }

    function swap(address executor, IGenericRouter.SwapDescription calldata desc, bytes calldata data)
        external
        payable
        returns (uint256, uint256)
    {
        if (shouldRevert) revert("Mock swap revert");
        emit SwapCalled(executor, address(desc.srcToken), address(desc.dstToken), desc.srcReceiver, desc.dstReceiver, desc.amount, desc.minReturnAmount, desc.flags, data);
        return (returnAmount, spentAmount);
    }
}

contract RouterTest is Test {
    Router public router;
    MockERC20 public srcToken;
    MockERC20 public dstToken;
    Mock1InchRouter public mock1Inch;
    address public user = address(0x123);

    function setUp() public {
   
        srcToken = new MockERC20("MockSrc", "SRC", 18);
        dstToken = new MockERC20("MockDst", "DST", 18);
        mock1Inch = new Mock1InchRouter();
        router = new Router(address(mock1Inch),address(srcToken),address(dstToken));
        // Give user some tokens
        srcToken.mint(user, 1000 ether);
        vm.startPrank(user);
        srcToken.approve(address(router), type(uint256).max);
        vm.stopPrank();
    }

    function testPerformSwapSuccess() public {
        // Set up swap description
        IGenericRouter.SwapDescription memory desc = IGenericRouter.SwapDescription({
            srcToken: IERC20(address(srcToken)),
            dstToken: IERC20(address(dstToken)),
            srcReceiver: payable(address(router)),
            dstReceiver: payable(user),
            amount: 100 ether,
            minReturnAmount: 90 ether,
            flags: 0
        });
        mock1Inch.setReturn(110 ether, 100 ether);
        bytes memory data = "";
        // Call performSwap
        vm.startPrank(user);
        (uint256 returnAmount, uint256 spentAmount) = router.performSwap(address(0), desc, data);
        vm.stopPrank();
        assertEq(returnAmount, 110 ether);
        assertEq(spentAmount, 100 ether);
        assertEq(srcToken.balanceOf(address(router)), 100 ether);
    }

    function testPerformSwapRevertsOnFailure() public {
        IGenericRouter.SwapDescription memory desc = IGenericRouter.SwapDescription({
            srcToken: IERC20(address(srcToken)),
            dstToken: IERC20(address(dstToken)),
            srcReceiver: payable(address(router)),
            dstReceiver: payable(user),
            amount: 100 ether,
            minReturnAmount: 90 ether,
            flags: 0
        });
        mock1Inch.setRevert(true);
        bytes memory data = "";
        vm.startPrank(user);
        vm.expectRevert();
        router.performSwap(address(0), desc, data);
        vm.stopPrank();
    }
}