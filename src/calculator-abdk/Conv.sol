// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.24;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

contract Conv {
    using ABDKMath64x64 for int128;

    uint256 constant RAY = 1e27;
    uint256 constant SECONDS_PER_YEAR = 31536000;
    uint256 constant BASIS_POINTS_SCALE = 10000;
    int128 constant HALF_BASIS_POINT = 0x8000000000000000; // 0.5 in 64.64
    int128 constant LN_2_64x64 = 0xb17217f7d1cf79ac; // ln(2) in 64.64 format

    /// @notice Converts a yearly rate in basis points (0.01%) to a per-second rate in ray (1e27)
    /// @param basisPoints The yearly rate in basis points (e.g., 500 for 5%)
    /// @return The per-second rate in ray format
    function turn(uint256 basisPoints) public pure returns (uint256) {
        require(basisPoints <= 9899, "Rate cannot exceed 98.99%");

        if (basisPoints == 0) {
            return RAY;
        }

        int128 yearlyRate = ABDKMath64x64.divu(basisPoints, BASIS_POINTS_SCALE);

        int128 onePlusRate = ABDKMath64x64.add(ABDKMath64x64.fromInt(1), yearlyRate);
        int128 lnOnePlusR = ABDKMath64x64.ln(onePlusRate);

        int128 perSecond = ABDKMath64x64.div(lnOnePlusR, ABDKMath64x64.fromUInt(SECONDS_PER_YEAR));

        uint256 result = ABDKMath64x64.mulu(ABDKMath64x64.exp(perSecond), RAY);

        return result < RAY ? RAY : result;
    }

    /// @notice Converts a ray (1e27) rate to APY in basis points
    /// @param rayRate The rate in ray format
    /// @return The yearly rate in basis points
    function nrut(uint256 rayRate) public pure returns (uint256) {
        require(rayRate > 0, "Rate must be positive");

        if (rayRate == RAY) {
            return 0;
        }

        int128 rate = ABDKMath64x64.divu(rayRate, RAY);
        require(rate > 0, "Invalid rate conversion");

        int128 lnRate = ABDKMath64x64.ln(rate);

        int128 secondsPerYear64x64 = ABDKMath64x64.fromUInt(SECONDS_PER_YEAR);
        int128 lnYearlyRate = ABDKMath64x64.mul(lnRate, secondsPerYear64x64);

        int128 yearlyRate = ABDKMath64x64.exp(lnYearlyRate);

        int128 rateAsDecimal = ABDKMath64x64.sub(yearlyRate, ABDKMath64x64.fromInt(1));

        int128 basisPointsFixed = ABDKMath64x64.mul(rateAsDecimal, ABDKMath64x64.fromUInt(BASIS_POINTS_SCALE));
        int128 roundedBps = ABDKMath64x64.add(basisPointsFixed, HALF_BASIS_POINT);
        uint256 basisPoints = ABDKMath64x64.toUInt(roundedBps);

        return basisPoints;
    }
}
