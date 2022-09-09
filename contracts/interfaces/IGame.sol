// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGame {
    struct DepositItemFromNFTStruct {
        string id;
        address itemAddress;
        uint256 tokenId;
        string itemType;
        string extraType;
        string nonce;
        bytes signature;
    }

    function depositItemFromNFT(DepositItemFromNFTStruct memory data) external;
}
