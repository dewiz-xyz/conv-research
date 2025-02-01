// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import "../TestBase.sol";
import "../../src/optimized-storage/Conv.sol";

contract RatesTest is RatesTestBase {

    function setUp() public override {
        conv = ConvLike(address(new Conv()));
    }
}
