# LLMOracleRegistry
[Git Source](https://github.com/firstbatchxyz/dria-oracle-contracts/blob/54ba49f9d68ffe125f895dc1163a0d8eafbad503/src/LLMOracleRegistry.sol)

**Inherits:**
[Whitelist](/src/Whitelist.sol/abstract.Whitelist.md), UUPSUpgradeable

Holds the addresses that are eligible to respond to LLM requests.

*There may be several types of oracle kinds, and each require their own stake.*


## State Variables
### generatorStakeAmount
Stake amount to be registered as an Oracle that can serve generation requests.


```solidity
uint256 public generatorStakeAmount;
```


### validatorStakeAmount
Stake amount to be registered as an Oracle that can serve validation requests.


```solidity
uint256 public validatorStakeAmount;
```


### minRegistrationTime
Minimum registration time for oracles.

*This is to prevent spamming the registry mechanism.*

*If the oracle wants to unregister, they have to wait at least this time before doing so.*


```solidity
uint256 public minRegistrationTime;
```


### registrations
Registrations per address & kind. If amount is 0, it is not registered.


```solidity
mapping(address oracle => mapping(LLMOracleKind => uint256 amount)) public registrations;
```


### registrationTimes
Registered times per oracle.


```solidity
mapping(address oracle => mapping(LLMOracleKind => uint256 registeredTime)) public registrationTimes;
```


### token
Token used for staking.


```solidity
ERC20 public token;
```


## Functions
### constructor

Locks the contract, preventing any future re-initialization.

*[See more](https://docs.openzeppelin.com/contracts/5.x/api/proxy#Initializable-_disableInitializers--).*

**Note:**
oz-upgrades-unsafe-allow: constructor


```solidity
constructor();
```

### _authorizeUpgrade

Function that should revert when `msg.sender` is not authorized to upgrade the contract.

*Called by and upgradeToAndCall.*


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyOwner;
```

### initialize

*Sets the owner to be the deployer, sets initial stake amount.*


```solidity
function initialize(
    uint256 _generatorStakeAmount,
    uint256 _validatorStakeAmount,
    address _token,
    uint256 _minRegistrationTime
) public initializer;
```

### register

Register an Oracle.

*Reverts if the user is already registered or has insufficient funds.*


```solidity
function register(LLMOracleKind kind) public;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`kind`|`LLMOracleKind`|The kind of Oracle to unregister.|


### unregister

Remove registration of an Oracle.

*Reverts if the user is not registered.*


```solidity
function unregister(LLMOracleKind kind) public returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`kind`|`LLMOracleKind`|The kind of Oracle to unregister.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of stake approved back.|


### setStakeAmounts

Set the stake amount required to register as an Oracle.

*Only allowed by the owner.*


```solidity
function setStakeAmounts(uint256 _generatorStakeAmount, uint256 _validatorStakeAmount) public onlyOwner;
```

### getStakeAmount

Returns the stake amount required to register as an Oracle w.r.t given kind.


```solidity
function getStakeAmount(LLMOracleKind kind) public view returns (uint256);
```

### isRegistered

Check if an Oracle is registered.


```solidity
function isRegistered(address user, LLMOracleKind kind) public view returns (bool);
```

## Events
### Registered
The Oracle response to an LLM generation request.


```solidity
event Registered(address indexed, LLMOracleKind kind);
```

### Unregistered
The Oracle response to an LLM generation request.


```solidity
event Unregistered(address indexed, LLMOracleKind kind);
```

## Errors
### NotRegistered
The user is not registered.


```solidity
error NotRegistered(address);
```

### AlreadyRegistered
The user is already registered.


```solidity
error AlreadyRegistered(address);
```

### InsufficientFunds
Insufficient stake amount during registration.


```solidity
error InsufficientFunds();
```

### TooEarlyToUnregister
Minimum waiting time has not passed for unregistering.


```solidity
error TooEarlyToUnregister(uint256 minTimeToWait);
```

