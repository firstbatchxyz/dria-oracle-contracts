# LLMOracleTaskParameters
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/4083e0e4f3f5849460fbea5040ecc77651509d1c/src/LLMOracleTask.sol)

Collection of oracle task-related parameters.

*Prevents stack-too-deep with tight-packing.*


```solidity
struct LLMOracleTaskParameters {
    uint8 difficulty;
    uint40 numGenerations;
    uint40 numValidations;
}
```

