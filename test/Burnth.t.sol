// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/contracts/Burnth.sol";

contract BurnthTest is Test {
    Burnth burnth;

    function setUp() public {
        burnth = new Burnth();
    }

    function testDeployment() public {
        assertEq(burnth.name(), "Burnth");
        assertEq(burnth.symbol(), "BURNTH");
    }

}
