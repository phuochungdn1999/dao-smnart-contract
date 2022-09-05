// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBlacklist {
    function isBanned(address _user) external view returns (bool);
}
