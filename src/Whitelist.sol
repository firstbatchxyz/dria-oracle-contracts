// SPDX-License-Identifier: Apache-2.0

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

pragma solidity ^0.8.20;

abstract contract Whitelist is OwnableUpgradeable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /// @notice Added address to whitelist
    event AddedToWhitelist(address indexed account);

    /// @notice Removed address from whitelist
    event RemovedFromWhitelist(address indexed account);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error to be thrown when a non-whitelisted address tries to access a function.
    error NotWhitelisted(address validator);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice To keep track of whitelisted addresses.
    mapping(address => bool) public whitelisted;

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
    function removeFromWhitelist(address account) public onlyOwner {
        if (whitelisted[account]) {
            whitelisted[account] = false;
            emit RemovedFromWhitelist(account);
        }
    }
}
