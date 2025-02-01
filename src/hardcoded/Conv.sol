// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

interface RatesLike {
    function turn(uint256 bps) external view returns (uint256);
}

contract Conv {

    address[] public rates;

    constructor(address[] memory _rates) {
        rates = _rates;
    }

    function turn(uint256 bps) external view returns (uint256 rate) {
        rate = RatesLike(rates[bps / 800]).turn(bps);
    }
}