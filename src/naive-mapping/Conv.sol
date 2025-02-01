// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

contract Conv {
    uint256[] internal rates;

    function setRates(bytes calldata _rates) external {
        // Each rate is 12 bytes
        uint256 numRates = _rates.length / 12;
        require(_rates.length % 12 == 0, "Invalid length");

        // Start from current length
        uint256 startIndex = rates.length;
        
        // Extend array to accommodate new rates
        for (uint256 i = 0; i < numRates;) {
            rates.push();
            unchecked { ++i; }
        }

        // Unpack bytes into rates array
        for (uint256 i = 0; i < numRates;) {
            uint256 rate;
            assembly {
                // Calculate position in calldata:
                // Skip 4 bytes function selector + 32 bytes offset + 32 bytes length
                // Then add 12 bytes for each rate
                let pos := add(68, mul(i, 12))
                
                // Load 32 bytes starting at our position
                let word := calldataload(pos)
                
                // Shift right by 20 bytes (160 bits) to align our 12 bytes
                // No need to mask as we're already only loading 12 bytes
                rate := shr(160, word)
            }
            rates[startIndex + i] = rate;
            unchecked { ++i; }
        }
    }

    function turn(uint256 bps) external view returns (uint256) {
        require(bps < rates.length, "Rate not set");
        return rates[bps];
    }

    function ratesLength() external view returns (uint256) {
        return rates.length;
    }
}