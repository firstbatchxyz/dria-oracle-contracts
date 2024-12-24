# Statistics
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/84413650904832c21815ffefb6eee8517ceb0ffc/src/Statistics.sol)

Simple statistic library for uint256 arrays.


## State Variables
### SCALING_FACTOR

```solidity
uint256 constant SCALING_FACTOR = 1e18;
```


## Functions
### avg

Compute the mean of the data.


```solidity
function avg(uint256[] memory data) internal pure returns (uint256 ans);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`uint256[]`|The data to compute the mean for.|


### variance

Compute the variance of the data.


```solidity
function variance(uint256[] memory data) internal pure returns (uint256 ans, uint256 mean);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`uint256[]`|The data to compute the variance for.|


### stddev

Compute the standard deviation of the data.

*Computes variance, and takes the square root.*


```solidity
function stddev(uint256[] memory data) internal pure returns (uint256 ans, uint256 mean);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`data`|`uint256[]`|The data to compute the standard deviation for.|


## Errors
### ComputeError

```solidity
error ComputeError();
```

