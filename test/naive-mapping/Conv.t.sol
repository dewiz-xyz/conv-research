// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import "../TestBase.sol";
import "../../src/naive-mapping/Conv.sol";

contract RatesTest is RatesTestBase {
    uint256 constant CHUNK_SIZE = 1000;

    function setUp() public override {
        conv = ConvLike(address(new Conv()));

        uint256 totalRates = 5001; // 0 to 5000 inclusive
        uint256 numChunks = (totalRates + CHUNK_SIZE - 1) / CHUNK_SIZE;

        for (uint256 chunk = 0; chunk < numChunks;) {
            // Calculate start and end indices for this chunk
            uint256 startIdx = chunk * CHUNK_SIZE;
            uint256 endIdx = startIdx + CHUNK_SIZE;
            if (endIdx > totalRates) endIdx = totalRates;
            uint256 chunkLength = endIdx - startIdx;

            // Pack rates for this chunk
            bytes memory packedRates = new bytes(chunkLength * 12);
            for (uint256 i = 0; i < chunkLength;) {
                uint256 rate = ratesMapping.rates(startIdx + i);
                if (startIdx + i == 0) {
                    console.log("Rate for 0 bps:", rate);
                }

                // Pack rate into 12 bytes
                assembly {
                    // Calculate position in memory where we'll write the rate
                    // Skip 32 bytes for the length prefix
                    let pos := add(add(packedRates, 32), mul(i, 12))

                    // Store the rate (left-aligned in the 12 bytes)
                    mstore(pos, shl(160, rate))
                }
                unchecked {
                    ++i;
                }
            }

            conv.setRates(packedRates);

            unchecked {
                ++chunk;
            }
        }

        // Verify all rates were set correctly
        assertEq(conv.ratesLength(), totalRates, "Wrong number of rates");
    }
}
