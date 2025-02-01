// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import "../TestBase.sol";
import "../../src/calculator-abdk/Conv.sol";

contract RatesTest is CalculatorBase {
    function setUp() public override {
        conv = ConvLike(address(new Conv()));
    }
}
