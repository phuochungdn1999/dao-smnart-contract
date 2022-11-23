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
import "../interfaces/IBlacklist.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract MarketplaceV3Upgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeERC20Upgradeable for IERC20Upgradeable;

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
        bool useBUSD;
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
        bool useBUSD;
        string nonce;
        bytes signature;
    }

    struct BuyItemStruct {
        string id;
        address tokenAddress;
        uint256 amount;
        bool useBUSD;
        string nonce;
        bytes signature;
    }

    event OfferEvent(
        string id,
        string itemType,
        string extraType,
        bool useBUSD,
        uint256[] price,
        address[] tokenAddress,
        uint256 indexed tokenId,
        address indexed owner
        // uint64 timestamp
    );

    event BuyEvent(
        string id,
        string itemType,
        string extraType,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price,
        bool useBUSD,
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

    event Paused(address account);

    event Unpaused(address account);

    string public constant _SIGNING_DOMAIN = "Marketplace-Item";
    string private constant _SIGNATURE_VERSION = "1";

    address public feesCollectorAddress;
    uint256 public feesCollectorCutPerMillion;
    mapping(string => ItemStruct) public itemsMap;
    mapping(string => bool) private _noncesMap;
    mapping(string => mapping(address => uint256)) private tokenPrice;
    mapping(address => bool) private allowedToken;

    address public operator;
    address public banContractAddress;
    bool private _paused;

    modifier isBanned(address _user) {
        require(!IBlacklist(banContractAddress).isBanned(_user), "Banned");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

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

    function offer(OrderItemStruct calldata data)
        public
        nonReentrant
        isBanned(_msgSender())
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyOrderItem(data);
        // Make sure that the signer is authorized to offer item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        if (!itemsMap[data.id].isExist) {
            IERC721Upgradeable(data.itemAddress).safeTransferFrom(
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

        itemsMap[data.id] = ItemStruct({
            id: data.id,
            itemType: data.itemType,
            extraType: data.extraType,
            itemAddress: data.itemAddress,
            tokenId: data.tokenId,
            owner: _msgSender(),
            price: 0,
            priceList: data.price,
            tokenAddress: data.tokenAddress,
            isExist: true,
            useBUSD: data.useBUSD
        });

        emit OfferEvent(
            data.id,
            data.itemType,
            data.extraType,
            data.useBUSD,
            data.price,
            data.tokenAddress,
            data.tokenId,
            _msgSender()
            // uint64(block.timestamp)
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
                            "OrderItemStruct(address walletAddress,string id,string itemType,string extraType,uint256 tokenId,address itemAddress,uint256[] price,address[] tokenAddress,bool useBUSD,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.id)),
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.extraType)),
                        data.tokenId,
                        data.itemAddress,
                        keccak256(abi.encodePacked(data.price)),
                        keccak256(abi.encodePacked(data.tokenAddress)),
                        data.useBUSD,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function buy(BuyItemStruct calldata data)
        public
        payable
        nonReentrant
        isBanned(_msgSender())
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyBuyItem(data);
        // Make sure that the signer is authorized to offer item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Check exists & don't buy own
        require(itemsMap[data.id].isExist, "Item is not in marketplace");
        require(
            itemsMap[data.id].owner != _msgSender(),
            "You cannot buy your own item"
        );

        ItemStruct memory item = itemsMap[data.id];

        uint256 totalFeesShareAmount = (data.amount *
            feesCollectorCutPerMillion) / 1_000_000;
        uint256 ownerShareAmount = data.amount - totalFeesShareAmount;

        // Transfer payment
        if (data.tokenAddress == address(0)) {
            require(msg.value == data.amount, "Not same price");
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
            IERC20Upgradeable(data.tokenAddress).safeTransferFrom(
                _msgSender(),
                feesCollectorAddress,
                totalFeesShareAmount
            );
            IERC20Upgradeable(data.tokenAddress).safeTransferFrom(
                _msgSender(),
                item.owner,
                ownerShareAmount
            );
        }

        IERC721Upgradeable(item.itemAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            item.tokenId
        );

        emit BuyEvent(
            item.id,
            item.itemType,
            item.extraType,
            item.tokenId,
            item.owner,
            data.amount,
            data.useBUSD,
            data.tokenAddress,
            _msgSender(),
            uint64(block.timestamp)
        );

        delete itemsMap[data.id];
    }

    function _verifyBuyItem(BuyItemStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashBuyItem(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashBuyItem(BuyItemStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BuyItemStruct(string id,address tokenAddress,uint256 amount,bool useBUSD,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.tokenAddress,
                        data.amount,
                        data.useBUSD,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function withdraw(string memory id)
        public
        nonReentrant
        isBanned(_msgSender())
        whenNotPaused
    {
        require(itemsMap[id].owner == _msgSender(), "You don't own this item");

        ItemStruct memory item = itemsMap[id];

        IERC721Upgradeable(item.itemAddress).safeTransferFrom(
            address(this),
            _msgSender(),
            item.tokenId
        );

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

    function setAllowedToken(address token, bool isAllowed) external onlyOwner {
        allowedToken[token] = isAllowed;
        emit AllowNewToken(token, isAllowed);
    }

    function getAllowedToken(address token) public view returns (bool) {
        return allowedToken[token];
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setBanContractAddress(address data) external onlyOwner {
        banContractAddress = data;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function setPause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function setUnpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
