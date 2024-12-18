# LLMOracleTaskParameters
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/a0589a694000a1a1e8d0cf54f0527c1c8a33c301/src/LLMOracleTask.sol)

Collection of oracle task-related parameters.

*Prevents stack-too-deep with tight-packing.*


```solidity
struct LLMOracleTaskParameters {
    uint8 difficulty;
    uint40 numGenerations;
    uint40 numValidations;
}
```

