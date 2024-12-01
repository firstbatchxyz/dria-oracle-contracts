# Whitelist
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/25076f552be543b6671d41de960346e5a3ad8aaf/src/Whitelist.sol)

**Inherits:**
OwnableUpgradeable


## State Variables
### whitelisted
To keep track of whitelisted addresses.


```solidity
mapping(address => bool) public whitelisted;
```


## Functions
### addToWhitelist

Adding multiple validators to whitelist.


```solidity
function addToWhitelist(address[] memory accounts) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`accounts`|`address[]`|The list of addresses to be added to the whitelist.|


### removeFromWhitelist

Remove validator from whitelist


```solidity
function removeFromWhitelist(address account) public onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address to be removed from the whitelist.|


## Events
### AddedToWhitelist
Added address to whitelist


```solidity
event AddedToWhitelist(address indexed account);
```

### RemovedFromWhitelist
Removed address from whitelist


```solidity
event RemovedFromWhitelist(address indexed account);
```

## Errors
### NotWhitelisted
Error to be thrown when a non-whitelisted address tries to access a function.


```solidity
error NotWhitelisted(address validator);
```

