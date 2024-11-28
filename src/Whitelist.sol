// SPDX-License-Identifier: Apache-2.0

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

pragma solidity ^0.8.20;

abstract contract Whitelist is OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    /// @notice Error to be thrown when a non-whitelisted address tries to access a function.
    /// @dev Used in the isWhiteListed modifier.
    error NotWhitelisted(address validator);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice To keep track of whitelisted addresses.
    mapping(address => bool) public whitelisted;

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice To check if the given address is whitelisted.
    /// @param validator The address to check if it is whitelisted.
    /// @dev Reverts if the `validator` is not whitelisted.
    modifier isWhiteListed(address validator) {
        if (!whitelisted[validator]) {
            revert NotWhitelisted(validator);
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                  LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Adding multiple validators to whitelist.
    /// @param accounts The list of addresses to be added to the whitelist.
    function addToWhitelist(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (!whitelisted[accounts[i]]) {
                whitelisted[accounts[i]] = true;
                emit AddedToWhitelist(accounts[i]);
            }
        }
    }

    /// @notice Remove validator from whitelist
    /// @param account The address to be removed from the whitelist.
    function removeFromWhitelist(address account) external onlyOwner {
        if (whitelisted[account]) {
            whitelisted[account] = false;
            emit RemovedFromWhitelist(account);
        }
    }
}
