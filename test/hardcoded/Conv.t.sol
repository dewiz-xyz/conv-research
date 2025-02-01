// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import "../TestBase.sol";
import "../../src/hardcoded/Conv.sol";
import "../../src/hardcoded/repositories/Rates0To799.sol";
import "../../src/hardcoded/repositories/Rates800To1599.sol";
import "../../src/hardcoded/repositories/Rates1600To2399.sol";
import "../../src/hardcoded/repositories/Rates2400To3199.sol";
import "../../src/hardcoded/repositories/Rates3200To3999.sol";
import "../../src/hardcoded/repositories/Rates4000To4799.sol";
import "../../src/hardcoded/repositories/Rates4800To5000.sol";

contract RatesTest is RatesTestBase {

    function setUp() public override {
        address[] memory rateAddresses = new address[](7);
        rateAddresses[0] = address(new Rates0To799());
        rateAddresses[1] = address(new Rates800To1599());
        rateAddresses[2] = address(new Rates1600To2399());
        rateAddresses[3] = address(new Rates2400To3199());
        rateAddresses[4] = address(new Rates3200To3999());
        rateAddresses[5] = address(new Rates4000To4799());
        rateAddresses[6] = address(new Rates4800To5000());

        conv = ConvLike(address(new Conv(rateAddresses)));
    }
}
