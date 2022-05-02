// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface INFT {
    function mintFromGame(
        address to,
        string calldata id,
        string calldata itemType
    ) external returns (uint256);
}
