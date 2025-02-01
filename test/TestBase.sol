pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "./RatesMapping.sol";

interface ConvLike {
    function turn(uint256 bps) external view returns (uint256);
    function nrut(uint256 ray) external view returns (uint256);
    function setRates(bytes calldata _rates) external;
    function ratesLength() external view returns (uint256);
}

abstract contract RatesTestBase is Test {
    ConvLike conv;
    RatesMapping public ratesMapping = new RatesMapping();
    uint256 public maxBps = 5000;

    function setUp() public virtual;

    function testCompareAllRates() public virtual {
        for (uint256 bps = 0; bps <= maxBps; bps++) {
            uint256 mappingRate = ratesMapping.rates(bps);
            uint256 bytesRate = conv.turn(bps);

            assertEq(bytesRate, mappingRate, string.concat("Rate mismatch at bps=", vm.toString(bps)));
        }
    }

    function testRevertsForInvalidBps() public {
        vm.expectRevert();
        conv.turn(maxBps + 1);

        vm.expectRevert();
        conv.turn(maxBps + 100);

        vm.expectRevert();
        conv.turn(1000 ether);
    }

    function testGas() public {
        uint256 gasBefore = gasleft();
        setUp();
        console.log("Deploy: ", gasBefore - gasleft());

        for (uint256 i; i <= 5000; i += 123) {
            gasBefore = gasleft();
            conv.turn(i);
            console.log("Turn bps", i, ":", gasBefore - gasleft());
        }
    }

    function testFuzz(uint256 bps) public virtual {
        try conv.turn(bps) returns (uint256 result) {
            assertTrue(bps <= maxBps);
            assertEq(result, ratesMapping.rates(bps));
        } catch {
            assertTrue(bps > maxBps);
        }
    }    
}

abstract contract CalculatorBase is RatesTestBase {
    // not testing with full precision
    function testCompareAllRates() public override {
        vm.skip(true);
    }
    function testFuzz(uint256) public override {
        vm.skip(true);
    }

    function _rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }    
    uint256 constant ONE = 10 ** 27;

    constructor() {
        maxBps = type(uint256).max;
    }

    function testApproxMatch() public view {
        for (uint256 i = 0; i < 9899; i++) {
            uint256 basisPoints = i;
            uint256 mappingRate = ratesMapping.rates(basisPoints);
            uint256 calculatedRate = conv.turn(basisPoints);
            
            uint256 tolerance = 1e10;
            assertTrue(
                calculatedRate >= mappingRate - tolerance && 
                calculatedRate <= mappingRate + tolerance,
                string.concat("Rate mismatch for ", vm.toString(basisPoints), " basis points")
            );
        }
    }

    function testRoundTrip() public {
        for (uint256 i = 0; i < 9899; i++) {
            uint256 basisPoints = i;
            uint256 rayRate = conv.turn(basisPoints);
            uint256 roundTrip = conv.nrut(rayRate);
            
            emit log_string(string.concat(
                "Input basis points: ", vm.toString(basisPoints),
                "\nRay rate: ", vm.toString(rayRate),
                "\nRound trip basis points: ", vm.toString(roundTrip)
            ));
            
            assertEq(roundTrip, basisPoints, "Round trip conversion failed");
        }
    }    

    function testPracticalDifferenceAcceptable() public {
        uint256 initialDebt = 100 * 1e18;
        uint256 secondsPerYear = 31536000;
        
        for (uint256 i = 0; i < 9899; i++) {
            uint256 basisPoints = i;
            uint256 mappingRate = ratesMapping.rates(basisPoints);
            uint256 calculatedRate = conv.turn(basisPoints);
            
            // uint256 mappingDebt = (initialDebt * mappingRate) / 1e27;
            uint256 mappingDebt = (initialDebt * _rpow(mappingRate, secondsPerYear, ONE)) / 1e27;
            // uint256 calculatedDebt = (initialDebt * calculatedRate) / 1e27;
            uint256 calculatedDebt = (initialDebt * _rpow(calculatedRate, secondsPerYear, ONE)) / 1e27;
            
            uint256 diff = mappingDebt > calculatedDebt ? 
                mappingDebt - calculatedDebt : 
                calculatedDebt - mappingDebt;
            
            if (diff > 1e9) {
                emit log_string(string.concat(
                    "Significant difference at ", vm.toString(basisPoints), " bps:\n",
                    "Mapping debt: ", vm.toString(mappingDebt / 1e27), ".", vm.toString((mappingDebt % 1e27) / 1e18), " units\n",
                    "Calculated debt: ", vm.toString(calculatedDebt / 1e27), ".", vm.toString((calculatedDebt % 1e27) / 1e18), " units\n",
                    "Difference: ", vm.toString(diff / 1e18), ".", vm.toString(diff % 1e18), " units"
                ));
            }
            
            // Ensure difference is within 0.0000001%
            assertLe(diff, 1e12, string.concat("Too large difference at ", vm.toString(basisPoints), " bps"));
        }
    }
}