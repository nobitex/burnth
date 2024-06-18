// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Burnth} from "../src/contracts/Burnth.sol";

contract BurnthTest is Test {
    Burnth public burnth;

    function setUp() public {
        burnth = new Burnth();
    }
}
