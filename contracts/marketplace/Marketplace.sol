// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract MarketplaceUpgradeable is
    Initializable,
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string public constant SIGNING_DOMAIN = "MarketplaceItem";
    string private constant SIGNATURE_VERSION = "1";

    address public feesCollector;
    mapping(string => Item) public available;

    struct Item {
        uint256 tokenId;
        address owner;
        uint256 itemPrice;
        address itemAddress;
        bool exists;
    }

    struct OrderItem {
        address seller;
        string itemId;
        uint256 tokenId;
        uint256 itemPrice;
        address itemAddress;
        string nonce;
        bytes signature;
    }

    struct CartItem {
        address buyer;
        string itemId;
        uint256 feesCollectorCutPerMillion;
        uint256 coinPrice;
        uint256 tokenPrice;
        address tokenAddress;
        string nonce;
        bytes signature;
    }

    //For test
    address public secret;
    event Offer(
        string itemId,
        uint256 tokenId,
        uint256 itemPrice,
        address itemAddress,
        address seller,
        uint64 timestamp
    );

    event Buy(
        address seller,
        address buyer,
        string itemId,
        uint256 tokenId,
        uint256 itemPrice,
        address itemAddress,
        uint64 timestamp
    );

    event Withdraw(
        string itemId,
        uint256 tokenId,
        address itemAddress,
        address owner,
        uint64 timestamp
    );

    function initialize() public virtual initializer {
        __Marketplace_init();
    }

    function __Marketplace_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Marketplace_init_unchained();
    }

    function __Marketplace_init_unchained() internal initializer {
        feesCollector = _msgSender();
    }

    function setFeesCollector(address newFeesCollector) external onlyOwner {
        feesCollector = newFeesCollector;
    }

    function setSecret(address newSecret) external onlyOwner {
        secret = newSecret;
    }

    function offer(OrderItem calldata data) public nonReentrant {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyOrderItem(data);
        // Make sure that the signer is authorized to offer items
        require(signer == owner(), "Signature invalid or unauthorized");

        if (!available[data.itemId].exists) {
            IERC721Upgradeable(data.itemAddress).transferFrom(
                _msgSender(),
                address(this),
                data.tokenId
            );
        }

        available[data.itemId] = Item({
            tokenId: data.tokenId,
            owner: _msgSender(),
            itemPrice: data.itemPrice,
            itemAddress: data.itemAddress,
            exists: true
        });

        emit Offer(
            data.itemId,
            data.tokenId,
            data.itemPrice,
            data.itemAddress,
            _msgSender(),
            uint64(block.timestamp)
        );
    }

    function _verifyOrderItem(OrderItem calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashOrderItem(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashOrderItem(OrderItem calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "OrderItem(address seller,string itemId,uint256 tokenId,uint256 itemPrice,address itemAddress,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.itemId)),
                        data.tokenId,
                        data.itemPrice,
                        data.itemAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function buy(CartItem calldata data) public payable nonReentrant {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyCartItem(data);
        // Make sure that the signer is authorized to buy items
        require(signer == owner(), "Signature invalid or unauthorized");

        // Check exists & don't buy own
        require(available[data.itemId].exists, "Item is not in marketplace");
        require(
            available[data.itemId].owner != _msgSender(),
            "You cannot buy your own NFT"
        );

        Item memory item = available[data.itemId];

        // Transfer payment
        if (msg.value > 0 && data.coinPrice > 0) {
            require(msg.value >= data.coinPrice, "Not enough money");

            uint256 totalFeesShareAmount = (data.coinPrice *
                data.feesCollectorCutPerMillion) / 1_000_000;

            if (totalFeesShareAmount > 0) {
                payable(feesCollector).transfer(totalFeesShareAmount);
            }

            payable(item.owner).transfer(msg.value - totalFeesShareAmount);
        } else if (data.tokenPrice > 0) {
            require(
                IERC20Upgradeable(data.tokenAddress).balanceOf(_msgSender()) >=
                    data.coinPrice,
                "Not enough money"
            );

            uint256 totalFeesShareAmount = (data.tokenPrice *
                data.feesCollectorCutPerMillion) / 1_000_000;

            if (totalFeesShareAmount > 0) {
                IERC20Upgradeable(data.tokenAddress).transferFrom(
                    _msgSender(),
                    feesCollector,
                    totalFeesShareAmount
                );

                //For test
                IERC20Upgradeable(data.tokenAddress).transferFrom(
                    _msgSender(),
                    secret,
                    totalFeesShareAmount
                );
            }

            IERC20Upgradeable(data.tokenAddress).transferFrom(
                _msgSender(),
                item.owner,
                data.tokenPrice - 2 * totalFeesShareAmount
            );
        }

        IERC721Upgradeable(item.itemAddress).transferFrom(
            address(this),
            _msgSender(),
            item.tokenId
        );

        emit Buy(
            item.owner,
            _msgSender(),
            data.itemId,
            item.tokenId,
            item.itemPrice,
            item.itemAddress,
            uint64(block.timestamp)
        );

        delete available[data.itemId];
    }

    function _verifyCartItem(CartItem calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashCartItem(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashCartItem(CartItem calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "CartItem(address buyer,string itemId,uint256 feesCollectorCutPerMillion,uint256 coinPrice,uint256 tokenPrice,address tokenAddress,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.itemId)),
                        data.feesCollectorCutPerMillion,
                        data.coinPrice,
                        data.tokenPrice,
                        data.tokenAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function withdraw(string memory itemId) public nonReentrant {
        require(
            available[itemId].owner == _msgSender(),
            "You don't own this NFT"
        );

        Item memory item = available[itemId];

        IERC721Upgradeable(item.itemAddress).transferFrom(
            address(this),
            _msgSender(),
            item.tokenId
        );

        emit Withdraw(
            itemId,
            item.tokenId,
            item.itemAddress,
            _msgSender(),
            uint64(block.timestamp)
        );

        delete available[itemId];
    }
}
