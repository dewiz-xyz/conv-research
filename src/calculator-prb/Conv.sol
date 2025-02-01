// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import {UD60x18} from "prb-math/UD60x18.sol";

contract Conv {
    uint256 constant RAY = 1e27;
    uint256 constant SECONDS_PER_YEAR = 31536000;

    /// @notice Converts a yearly rate in basis points (0.01%) to a per-second rate in ray (1e27)
    /// @param basisPoints The yearly rate in basis points (e.g., 500 for 5%)
    /// @return The per-second rate in ray format
    function turn(uint256 basisPoints) public pure returns (uint256) {
        // Convert basis points to a decimal (div by 10000)
        // For 500 bps (5%), this gives 0.05
        UD60x18 yearlyRate = UD60x18.wrap(basisPoints * 1e14); // Scale to 1e18 first
        
        // ln(1 + r) for the yearly rate
        UD60x18 lnOnePlusR = UD60x18.wrap(1e18).add(yearlyRate).ln();
        
        // Divide by seconds per year to get per-second rate
        UD60x18 lnPerSecond = lnOnePlusR.div(UD60x18.wrap(SECONDS_PER_YEAR * 1e18));
        
        // e^(ln(1+r)/n) where n is seconds per year
        UD60x18 perSecondRate = lnPerSecond.exp();
        
        // Convert from 1e18 to RAY (1e27) precision
        return uint256(perSecondRate.unwrap()) * 1e9;
    }

    /// @notice Converts a ray (1e27) rate to APY in basis points
    /// @param rayRate The rate in ray format
    /// @return The yearly rate in basis points
    function nrut(uint256 rayRate) public pure returns (uint256) {
        // Convert from ray (1e27) to 1e18 precision
        UD60x18 rateIn18 = UD60x18.wrap(rayRate / 1e9);
        
        // Take ln of rate
        UD60x18 lnRate = rateIn18.ln();
        
        // Multiply by seconds per year
        UD60x18 lnYearlyRate = lnRate.mul(UD60x18.wrap(SECONDS_PER_YEAR * 1e18));
        
        // Take exp and subtract 1 to get the yearly rate
        UD60x18 yearlyRate = lnYearlyRate.exp().sub(UD60x18.wrap(1e18));
        
        // Convert to basis points (multiply by 10000)
        // Add half a basis point (0.005%) for proper rounding
        uint256 scaledRate = uint256(yearlyRate.unwrap()) * 10000;
        return (scaledRate + 5e17) / 1e18;
    }
}
