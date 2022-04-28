// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTUpgradeableV2 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ItemVoucherStruct {
        string id;
        string itemType;
        uint256 price;
        address priceTokenAddress;
        string nonce;
        bytes signature;
    }

    event RedeemEvent(
        address indexed user,
        string id,
        string itemType,
        uint256 tokenId,
        string nonce,
        uint64 timestamp
    );

    struct StarterBoxStruct {
        string id;
        uint256 tokenId;
        uint256 numberTokens;
        string nonce;
        bytes signature;
    }

    event OpenStarterBoxEvent(
        address indexed user,
        string id,
        uint256[] tokenIds,
        uint64 timestamp
    );

    struct CraftItemVoucherStruct {
        address user;
        string itemType;
        string nonce;
    }

    event RedeemCraftItemEvent(
        address indexed user,
        uint256 tokenId,
        string nonce,
        string itemType,
        uint64 timestamp
    );

    string private constant _SIGNING_DOMAIN = "NFT-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

    address public devWalletAddress;
    mapping(string => bool) private _noncesMap;
    mapping(address => bool) private _operators;
    CountersUpgradeable.Counter private _tokenIds;

    function initialize() public virtual initializer {
        __NFT_init();
    }

    function __NFT_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ERC721_init("NFT", "NFT");
        __Ownable_init();
        __NFT_init_unchained();
    }

    function __NFT_init_unchained() internal initializer {
        _operators[_msgSender()] = true;
        devWalletAddress = _msgSender();
    }

    modifier hasPrivilege(address msgSender) {
        require(_operators[msgSender], "You don't have privilege");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator");
        _operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        require(_operators[operator], "You're not operator");
        _operators[operator] = false;
    }

    function setDevWalletAddress(address data) external onlyOwner {
        devWalletAddress = data;
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function redeem(ItemVoucherStruct calldata data) public payable {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyItemVoucher(data);
        // Make sure that the signer is authorized to mint an item
        require(signer == owner(), "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Transfer payment
        ERC20Upgradeable(data.priceTokenAddress).transferFrom(
            _msgSender(),
            devWalletAddress,
            data.price
        );

        // Mint token
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_msgSender(), newTokenId);

        emit RedeemEvent(
            _msgSender(),
            data.id,
            data.itemType,
            newTokenId,
            data.nonce,
            uint64(block.timestamp)
        );
    }

    function _verifyItemVoucher(ItemVoucherStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashItemVoucher(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashItemVoucher(ItemVoucherStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ItemVoucherStruct(string id,string itemType,uint256 price,address priceTokenAddress,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        keccak256(bytes(data.itemType)),
                        data.price,
                        data.priceTokenAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function openStarterBox(StarterBoxStruct calldata data) public {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyStarterBox(data);
        // Make sure that the signer is authorized to open start box
        require(signer == owner(), "Signature invalid or unauthorized");

        // Check nonce & exists token id
        require(_exists(data.tokenId), "Approved query for nonexistent token");
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Mint more tokens
        uint256[] memory tokenIds = new uint256[](data.numberTokens);
        // Reuse token, do not need to burn and create an new one
        tokenIds[0] = data.tokenId;

        for (uint256 i = 1; i < data.numberTokens; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_msgSender(), newTokenId);
            tokenIds[i] = newTokenId;
        }

        emit OpenStarterBoxEvent(
            _msgSender(),
            data.id,
            tokenIds,
            uint64(block.timestamp)
        );
    }

    function _verifyStarterBox(StarterBoxStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashStarterBox(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashStarterBox(StarterBoxStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "StarterBoxStruct(string id,uint256 tokenId,uint256 numberTokens,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.tokenId,
                        data.numberTokens,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function redeemCraftItem(
        address user,
        string calldata itemType,
        string calldata nonce
    ) public {
        require(!_noncesMap[nonce], "The nonce has been used");
        _noncesMap[nonce] = true;

        // Mint token
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(user, newTokenId);

        emit RedeemCraftItemEvent(
            user,
            newTokenId,
            nonce,
            itemType,
            uint64(block.timestamp)
        );
    }

    function mint(address user) public {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(user, newTokenId);
    }
}
