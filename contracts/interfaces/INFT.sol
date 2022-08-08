// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface INFT {
    function mintFromGameAndBringToGame(
        address to,
        string calldata id,
        string calldata itemType,
        string calldata extraType
    ) external returns (uint256);
}
