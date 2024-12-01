# LLMOracleTaskParameters
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/25076f552be543b6671d41de960346e5a3ad8aaf/src/LLMOracleTask.sol)

Collection of oracle task-related parameters.

*Prevents stack-too-deep with tight-packing.
TODO: use 256-bit tight-packing here*


```solidity
struct LLMOracleTaskParameters {
    uint8 score;
    uint8 difficulty;
    uint40 numGenerations;
    uint40 numValidations;
}
```

