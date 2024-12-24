# LLMOracleTaskParameters
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/84413650904832c21815ffefb6eee8517ceb0ffc/src/LLMOracleTask.sol)

Collection of oracle task-related parameters.

*Prevents stack-too-deep with tight-packing.*


```solidity
struct LLMOracleTaskParameters {
    uint8 difficulty;
    uint40 numGenerations;
    uint40 numValidations;
}
```

