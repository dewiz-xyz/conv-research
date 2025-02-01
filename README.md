## Conv - Research

**Onchain repository for DSS rates**

Conv stores all per-second DSS rates for annualized BPSs in a single on-chain repository.

### Motivation

Some parts of the DSS protocol may need rate validation, such as the rate validation of the IAM module. This repository aims to implement that.

Requirements:
- The rates need to have full precision compared to rates currently used in DSS (https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6)
- Read cost should be reasonable, allowing other components of the system to use it without too much overhead.
- The contract needs to be deployable efficiently (low priority, one time cost).

### Research

In this repo, we explored several ways to store or calculate rates onchain. There are tradeoffs between different approaches as expected:

| Design   | Deployment Cost | Contract Size | Precision | Read Cost | Note |
| -------- | --------------- | ------------- | --------- | --------- | ---- |
| Plain mapping | 20M gas / 1k rates | Small | Full | 2k gas |
| Calculating onchain (ABDK lib) | low | Small | Lossy (though close) | 20k gas | External lib also used, not usually accepted for DSS modules |
| Calculating onchain (PRB lib) | low | Small | Lossy (though close) | 20k gas | External lib also used, not usually accepted for DSS modules |
| Hardcoded (script generated binary search in Solidity Assembly) | 7M gas / 1k rates | Large (fits up to 800 rates per contract) | Full | 3k gas |
| Optimized storage | 5.6M / 1k rates | Large (fits up to 5k rates on Ethereum mainnet, rates are hardcoded on the constructor) | Full | 3k gas

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Deploy

This code is not production ready. Do not deploy it in prod.