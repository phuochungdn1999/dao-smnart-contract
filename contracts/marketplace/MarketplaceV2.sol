// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MarketplaceV2Upgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct ItemStruct {
        string id;
        string itemType;
        string extraType;
        uint256 tokenId;
        address itemAddress;
        address owner;
        uint256 price;
        bool isExist;
        uint256[] priceList;
        address[] tokenAddress;
    }

    struct OrderItemStruct {
        address walletAddress;
        string id;
        string itemType;
        string extraType;
        uint256 tokenId;
        address itemAddress;
        uint256[] price;
        address[] tokenAddress;
        string nonce;
        bytes signature;
    }

    event OfferEvent(
        string indexed id,
        string itemType,
        string extraType,
        uint256 tokenId,
        address owner,
        uint256[] price,
        address[] tokenAddress,
        uint64 timestamp
    );

    event BuyEvent(
        string id,
        string itemType,
        string extraType,
        uint256 tokenId,
        address owner,
        uint256 price,
        address tokenAddress,
        address buyer,
        uint64 timestamp
    );

    event WithdrawEvent(
        string id,
        string itemType,
        string extraType,
        uint256 tokenId,
        address owner,
        uint64 timestamp
    );

    event AllowNewToken(address token, bool isAllowed);

    string public constant _SIGNING_DOMAIN = "Marketplace-Item";
    string private constant _SIGNATURE_VERSION = "1";

    address public feesCollectorAddress;
    uint256 public feesCollectorCutPerMillion;
    mapping(string => ItemStruct) public itemsMap;
    mapping(string => bool) private _noncesMap;
    mapping(string => mapping(address => uint256)) private tokenPrice;
    mapping(address => bool) private allowedToken;

    function initialize() public virtual initializer {
        __Marketplace_init();
    }

    function __Marketplace_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Marketplace_init_unchained();
    }

    function __Marketplace_init_unchained() internal initializer {
        feesCollectorAddress = _msgSender();
        feesCollectorCutPerMillion = 35_000; // 3.5%
    }

    function setFeesCollectorAddress(address data) external onlyOwner {
        feesCollectorAddress = data;
    }

    function setFeesCollectorCutPerMillion(uint256 data) external onlyOwner {
        feesCollectorCutPerMillion = data;
    }

    function offer(OrderItemStruct calldata data) public nonReentrant {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyOrderItem(data);
        // Make sure that the signer is authorized to offer item
        require(signer == owner(), "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Check price
        require(
            data.tokenAddress.length == data.price.length &&
                data.tokenAddress.length > 0,
            "Length price and token invalid"
        );

        if (!itemsMap[data.id].isExist) {
            IERC721Upgradeable(data.itemAddress).transferFrom(
                _msgSender(),
                address(this),
                data.tokenId
            );
        } else {
            require(
                _msgSender() == itemsMap[data.id].owner,
                "Not owner of NFT"
            );
        }
        updatePrice(data.id);

        itemsMap[data.id] = ItemStruct({
            id: data.id,
            itemType: data.itemType,
            extraType: data.extraType,
            itemAddress: data.itemAddress,
            tokenId: data.tokenId,
            owner: _msgSender(),
            price:0,
            priceList: data.price,
            tokenAddress: data.tokenAddress,
            isExist: true
        });

        for (uint256 i = 0; i < data.tokenAddress.length; i++) {
            require(
                allowedToken[data.tokenAddress[i]],
                "Not allowed token to sell"
            );
            require(data.price[i] > 0, "Price > 0");
            tokenPrice[data.id][data.tokenAddress[i]] = data.price[i];
        }

        emit OfferEvent(
            data.id,
            data.itemType,
            data.extraType,
            data.tokenId,
            _msgSender(),
            data.price,
            data.tokenAddress,
            uint64(block.timestamp)
        );
    }

    function _verifyOrderItem(OrderItemStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashOrderItem(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashOrderItem(OrderItemStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "OrderItemStruct(address walletAddress,string id,string itemType,string extraType,uint256 tokenId,address itemAddress,uint256[] price,address[] tokenAddress,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.id)),
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.extraType)),
                        data.tokenId,
                        data.itemAddress,
                        keccak256(abi.encodePacked(data.price)),
                        keccak256(abi.encodePacked(data.tokenAddress)),
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function buy(string memory id, address tokenAddress,uint256 amount)
        public
        payable
        nonReentrant
    {
        // Check exists & don't buy own
        require(itemsMap[id].isExist, "Item is not in marketplace");
        require(
            itemsMap[id].owner != _msgSender(),
            "You cannot buy your own item"
        );
        require(allowedToken[tokenAddress], "Token not for sale");
        require(
            msg.value == tokenPrice[id][tokenAddress] || tokenPrice[id][tokenAddress] == amount,
            "Not enough money"
        );

        ItemStruct memory item = itemsMap[id];

        uint256 totalFeesShareAmount = (tokenPrice[id][tokenAddress] *
            feesCollectorCutPerMillion) / 1_000_000;
        uint256 ownerShareAmount = tokenPrice[id][tokenAddress] -
            totalFeesShareAmount;

        // Transfer payment
        if (tokenAddress == address(0)) {
            //transfer with BNB
            if (totalFeesShareAmount > 0) {
                (bool success, ) = feesCollectorAddress.call{
                    value: totalFeesShareAmount
                }("");
                require(success, "Transfer fee failed");
            }

            (bool success, ) = item.owner.call{value: ownerShareAmount}("");
            require(success, "Transfer money failed");
        } else {
            // transfer with token
            IERC20Upgradeable(tokenAddress).transferFrom(
                _msgSender(),
                feesCollectorAddress,
                totalFeesShareAmount
            );
            IERC20Upgradeable(tokenAddress).transferFrom(
                _msgSender(),
                item.owner,
                ownerShareAmount
            );
        }

        IERC721Upgradeable(item.itemAddress).transferFrom(
            address(this),
            _msgSender(),
            item.tokenId
        );
        updatePrice(id);

        emit BuyEvent(
            item.id,
            item.itemType,
            item.extraType,
            item.tokenId,
            item.owner,
            tokenPrice[id][tokenAddress],
            tokenAddress,
            _msgSender(),
            uint64(block.timestamp)
        );

        delete itemsMap[id];
    }

    function withdraw(string memory id) public nonReentrant {
        require(itemsMap[id].owner == _msgSender(), "You don't own this item");

        ItemStruct memory item = itemsMap[id];

        IERC721Upgradeable(item.itemAddress).transferFrom(
            address(this),
            _msgSender(),
            item.tokenId
        );
        updatePrice(id);

        emit WithdrawEvent(
            item.id,
            item.itemType,
            item.extraType,
            item.tokenId,
            item.owner,
            uint64(block.timestamp)
        );

        delete itemsMap[id];
    }

    function updatePrice(string memory id) internal {
        if (itemsMap[id].tokenAddress.length > 0) {
            uint256 length = itemsMap[id].tokenAddress.length;
            for (uint256 i = 0; i < length; i++) {
                tokenPrice[id][itemsMap[id].tokenAddress[i]] = 0;
            }
        }
    }

    function setAllowedToken(address token, bool isAllowed) external onlyOwner {
        allowedToken[token] = isAllowed;
        emit AllowNewToken(token, isAllowed);
    }

    function getAllowedToken(address token) public view returns (bool) {
        return allowedToken[token];
    }
}
