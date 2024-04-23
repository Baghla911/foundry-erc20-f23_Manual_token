// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {DeployManualToken} from "../script/DeployManualToken.s.sol";
import {ManualToken} from "../src/ManualToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract ManualTokenTest is StdCheats, Test {
    ManualToken public token;
    DeployManualToken public deployer;

    uint256 public DHRUV_STARTING_AMOUNT = 5000 ether;
    address public dhruv;
    address public sharvil;
    address public deployerAddress;

    // Called before every function and sets up the initial state
    function setUp() public {
        // e = new Event(); // This line seems like a comment or unused code
        deployer = new DeployManualToken();
        token = deployer.run();

        // Token holder
        dhruv = makeAddr("dhruv");

        // Token receiver/spender
        sharvil = makeAddr("sharvil");

        deployerAddress = vm.addr(deployer.deployerKey());

        vm.prank(deployerAddress);
        token.transfer(dhruv, DHRUV_STARTING_AMOUNT);
    }
event Transfer(address indexed from, address indexed to, uint256 value);

function testEmittransfer() public {
    //e = new Event();
    vm.expectEmit(true, true, false, true);
    emit Transfer(dhruv, sharvil, 1000);
    vm.prank(dhruv);
    token.transfer(sharvil, 1000);
}

event Burn(address indexed from, uint256 value);

function testBurnEvent() public {
    vm.expectEmit(true, false, true, false);
    emit Burn(address(this), 0);
    vm.prank(address(this));
    token.burn(0);
}

event Approval(
    address indexed _owner,
    address indexed _dhruv,
    uint256 _value
);

function testEmitApproval() public {
    vm.expectEmit();
    emit Approval(deployerAddress, sharvil, 2000);
    vm.prank(deployerAddress);
    token.approve(sharvil, 2000);
}
function invariant_nameAndSymbol() public {
    string memory initialName = token.name();
    string memory initialSymbol = token.symbol();
    vm.prank(deployerAddress);
    assertEq(token.transfer(sharvil, 10000), true);
    vm.prank(deployerAddress);
    token.burn(1000);
    assertEq(initialName, token.name());
    assertEq(initialSymbol, token.symbol());
}

// Fuzz testing
function testfuzz_Transfer(uint8 value) public {
    uint initialBalances = token.balanceOf(sharvil) + token.balanceOf(dhruv);
    vm.prank(dhruv);
    token.transfer(sharvil, value);
    uint finalBalances = token.balanceOf(sharvil) + token.balanceOf(dhruv);
    assertEq(initialBalances, finalBalances);
}

// Stateful fuzzing function
function testFuzz_burnAmount(uint80 amountToBurn) public {
    vm.prank(deployerAddress);
    token.transfer(dhruv, amountToBurn);
    uint256 dhruvPreviousBalance = token.balanceOf(dhruv);
    uint256 previousTotalSupply = token.totalSupply();
    vm.prank(dhruv);
    token.burn(amountToBurn);
    assertEq(dhruvPreviousBalance - amountToBurn, token.balanceOf(dhruv));
    assertEq(previousTotalSupply - amountToBurn, token.totalSupply());
}
function testFuzz_burnFromAmount(uint80 amountToBurn) public {
    // Give dhruv tokens to spend
    vm.prank(deployerAddress);
    token.transfer(dhruv, amountToBurn);
    uint256 dhruvPreviousBalance = token.balanceOf(dhruv);
    uint256 previousTotalSupply = token.totalSupply();
    
    // Allocate 50 tokens to sharvil through dhruv
    vm.prank(dhruv);
    token.approve(sharvil, amountToBurn);
    vm.prank(sharvil);
    token.burnFrom(dhruv, amountToBurn);
    
    assertEq(dhruvPreviousBalance - amountToBurn, token.balanceOf(dhruv));
    
    uint256 dhruvAllowanceToSharvil = token.allowance(sharvil, dhruv);
    assertEq(dhruvAllowanceToSharvil, 0);
    assertEq(previousTotalSupply - amountToBurn, token.totalSupply());
}

// Unit test
function testFail_basic_unit() public {
    vm.prank(dhruv);
    token.approve(sharvil, 500);
    assertGe(token.allowance(dhruv, sharvil), 600);
}

function test_burn(uint256 amountToBurn) internal {
    uint256 previousTotalSupply = token.totalSupply();
    vm.prank(deployerAddress);
    token.burn(amountToBurn);
    assertEq(previousTotalSupply - amountToBurn, token.totalSupply());
}

function testInitialSupply() public {
    assertGe(token.totalSupply(), deployer.INITIAL_SUPPLY());
}

function testAllowances() public {
    uint256 initialAllowance = 1000;
    // Sharvil approves dhruv to spend tokens on her behalf
    vm.prank(dhruv);
    token.approve(sharvil, initialAllowance);
    uint256 transferAmount = 500;
    vm.prank(sharvil);
    token.transferFrom(dhruv, sharvil, transferAmount);
    assertEq(token.balanceOf(sharvil), transferAmount);
    assertEq(token.balanceOf(dhruv), DHRUV_STARTING_AMOUNT - transferAmount);
}



}
