# LLMOracleManager
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/84413650904832c21815ffefb6eee8517ceb0ffc/src/LLMOracleManager.sol)

**Inherits:**
OwnableUpgradeable

Holds the configuration for the LLM Oracle, such as allowed bounds on difficulty,
number of generations & validations, and fee settings.


## State Variables
### platformFee
A fixed fee paid for the platform.


```solidity
uint256 public platformFee;
```


### generationFee
The base fee factor for a generation of LLM generation.

*When scaled with difficulty & number of generations, we denote it as `generatorFee`.*


```solidity
uint256 public generationFee;
```


### validationFee
The base fee factor for a generation of LLM validation.

*When scaled with difficulty & number of validations, we denote it as `validatorFee`.*


```solidity
uint256 public validationFee;
```


### generationDeviationFactor
The deviation factor for the generation scores.


```solidity
uint64 public generationDeviationFactor;
```


### minimumParameters
Minimums for oracle parameters.


```solidity
LLMOracleTaskParameters public minimumParameters;
```


### maximumParameters
Maximums for oracle parameters.


```solidity
LLMOracleTaskParameters public maximumParameters;
```


### minScore
The minimum score for a generation.


```solidity
uint256 public minScore;
```


### maxScore
The maximum score for a generation.


```solidity
uint256 public maxScore;
```


## Functions
### __LLMOracleManager_init

Initialize the contract.


```solidity
function __LLMOracleManager_init(
    uint256 _platformFee,
    uint256 _generationFee,
    uint256 _validationFee,
    uint256 _minScore,
    uint256 _maxScore
) internal onlyInitializing;
```

### onlyValidParameters

Modifier to check if the given parameters are within the allowed range.


```solidity
modifier onlyValidParameters(LLMOracleTaskParameters calldata parameters);
```

### setFees

Update Oracle fees.

*To keep a fee unchanged, provide the same value.*


```solidity
function setFees(uint256 _platformFee, uint256 _generationFee, uint256 _validationFee) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_platformFee`|`uint256`|The new platform fee|
|`_generationFee`|`uint256`|The new generation fee|
|`_validationFee`|`uint256`|The new validation fee|


### getFee

Get the total fee for a given task setting.


```solidity
function getFee(LLMOracleTaskParameters calldata parameters)
    public
    view
    returns (uint256 totalFee, uint256 generatorFee, uint256 validatorFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`parameters`|`LLMOracleTaskParameters`|The task parameters.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalFee`|`uint256`|The total fee for the task.|
|`generatorFee`|`uint256`|The fee paid to each generator per generation.|
|`validatorFee`|`uint256`|The fee paid to each validator per validated generation.|


### setParameters

Update Oracle parameters bounds.

*Provide the same value to keep it unchanged.*


```solidity
function setParameters(LLMOracleTaskParameters calldata minimums, LLMOracleTaskParameters calldata maximums)
    public
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minimums`|`LLMOracleTaskParameters`|The new minimum parameters.|
|`maximums`|`LLMOracleTaskParameters`|The new maximum parameters.|


### setGenerationDeviationFactor

Update generation deviation factor.

*Provide the same value to keep it unchanged.*


```solidity
function setGenerationDeviationFactor(uint64 _generationDeviationFactor) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_generationDeviationFactor`|`uint64`|The new generation deviation factor.|


## Errors
### InvalidParameterRange
Given parameter is out of range.


```solidity
error InvalidParameterRange(uint256 have, uint256 min, uint256 max);
```

