# LLMOracleTaskParameters
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/54ba49f9d68ffe125f895dc1163a0d8eafbad503/src/LLMOracleTask.sol)

Collection of oracle task-related parameters.

*Prevents stack-too-deep with tight-packing.
TODO: use 256-bit tight-packing here*


```solidity
struct LLMOracleTaskParameters {
    uint8 difficulty;
    uint40 numGenerations;
    uint40 numValidations;
}
```

