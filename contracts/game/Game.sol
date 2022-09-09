// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/INFT.sol";
import "../interfaces/IBlacklist.sol";

contract GameUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    struct WithdrawTokenStruct {
        address walletAddress;
        bool isNativeToken;
        address tokenAddress;
        uint256 amount;
        string nonce;
        bytes signature;
    }

    event WithdrawTokenEvent(
        address indexed user,
        string nonce,
        uint64 timestamp
    );

    event DepositTokenEvent(
        address indexed user,
        bool isNativeToken,
        address tokenAddress,
        uint256 amount,
        uint64 timestamp
    );

    struct DepositItemStruct {
        string id;
        address itemAddress;
        uint256 tokenId;
        string itemType;
        string extraType;
        string nonce;
        bytes signature;
    }

    struct DepositItemFromNFTStruct {
        string id;
        address itemAddress;
        uint256 tokenId;
        string itemType;
        string extraType;
        string nonce;
        bytes signature;
    }

    event DepositItemEvent(
        string id,
        address indexed user,
        address itemAddress,
        uint256 tokenId,
        string itemType,
        string extraType,
        uint64 timestamp
    );

    event DepositItemFromNFTEvent(
        string id,
        address indexed user,
        address itemAddress,
        uint256 tokenId,
        string itemType,
        string extraType,
        uint64 timestamp
    );

    struct WithdrawItemStruct {
        address walletAddress;
        string id;
        address itemAddress;
        uint256 tokenId;
        string itemType;
        string extraType;
        string nonce;
        bytes signature;
    }

    event WithdrawItemEvent(
        string id,
        address indexed user,
        string itemType,
        string extraType,
        string nonce,
        uint64 timestamp
    );

    event Paused(address account);

    event Unpaused(address account);

    string private constant _SIGNING_DOMAIN = "NFT-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

    mapping(string => bool) private _noncesMap;

    address public operator;
    address public banContractAddress;
    bool private _paused;

    address public nftAddress;

    modifier isBanned(address _user) {
        require(!IBlacklist(banContractAddress).isBanned(_user), "Banned");
        _;
    }

    modifier onlyNFT() {
        require(_msgSender() == nftAddress, "Not NFT address");
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
        __Game_init();
    }

    function __Game_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Game_init_unchained();
    }

    function __Game_init_unchained() internal initializer {}

    function depositToken(uint256 amount, address tokenAddress)
        public
        isBanned(_msgSender())
        whenNotPaused
    {
        require(amount > 0, "Amount must be greater than zero");

        IERC20Upgradeable(tokenAddress).transferFrom(
            _msgSender(),
            address(this),
            amount
        );

        emit DepositTokenEvent(
            _msgSender(),
            false,
            tokenAddress,
            amount,
            uint64(block.timestamp)
        );
    }

    function depositNativeToken(uint256 amount)
        public
        payable
        isBanned(_msgSender())
        whenNotPaused
    {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.value == amount, "Value must be equal amount");

        emit DepositTokenEvent(
            _msgSender(),
            true,
            address(0),
            msg.value,
            uint64(block.timestamp)
        );
    }

    function withdrawToken(WithdrawTokenStruct calldata data)
        public
        payable
        nonReentrant
        isBanned(_msgSender())
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyWithdrawToken(data);
        // Make sure that the signer is authorized to withdraw tokens
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        if (data.isNativeToken) {
            payable(_msgSender()).transfer(data.amount);
        } else {
            IERC20Upgradeable(data.tokenAddress).transfer(
                _msgSender(),
                data.amount
            );
        }

        emit WithdrawTokenEvent(
            _msgSender(),
            data.nonce,
            uint64(block.timestamp)
        );
    }

    function _verifyWithdrawToken(WithdrawTokenStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashWithdrawToken(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashWithdrawToken(WithdrawTokenStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WithdrawTokenStruct(address walletAddress,bool isNativeToken,address tokenAddress,uint256 amount,string nonce)"
                        ),
                        _msgSender(),
                        data.isNativeToken,
                        data.tokenAddress,
                        data.amount,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function depositItem(DepositItemStruct calldata data) public whenNotPaused {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyDepositItem(data);
        // Make sure that the signer is authorized to deposit an item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        IERC721Upgradeable(data.itemAddress).transferFrom(
            _msgSender(),
            address(this),
            data.tokenId
        );

        emit DepositItemEvent(
            data.id,
            _msgSender(),
            data.itemAddress,
            data.tokenId,
            data.itemType,
            data.extraType,
            uint64(block.timestamp)
        );
    }

    function _verifyDepositItem(DepositItemStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashDepositItem(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashDepositItem(DepositItemStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "DepositItemStruct(string id,address itemAddress,uint256 tokenId,string itemType,string extraType,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.itemAddress,
                        data.tokenId,
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.extraType)),
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function withdrawItem(WithdrawItemStruct calldata data)
        public
        isBanned(_msgSender())
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyWithdrawItem(data);
        // Make sure that the signer is authorized to withdraw an item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        if (data.tokenId == 0) {
            INFT(data.itemAddress).mintFromGameAndBringToGame(
                _msgSender(),
                data.id,
                data.itemType,
                data.extraType
            );
        } else {
            IERC721Upgradeable(data.itemAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                data.tokenId
            );
            emit WithdrawItemEvent(
                data.id,
                _msgSender(),
                data.itemType,
                data.extraType,
                data.nonce,
                uint64(block.timestamp)
            );
        }
    }

    function _verifyWithdrawItem(WithdrawItemStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashWithdrawItem(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashWithdrawItem(WithdrawItemStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WithdrawItemStruct(address walletAddress,string id,address itemAddress,uint256 tokenId,string itemType,string extraType,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.id)),
                        data.itemAddress,
                        data.tokenId,
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.extraType)),
                        keccak256(bytes(data.nonce))
                    )
                )
            );
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

    function setNFTAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

    function depositItemFromNFT(DepositItemStruct calldata data)
        public
        whenNotPaused
        onlyNFT
    {
        // Make sure signature is valid and get the address of the signer
        // address signer = _verifyDepositItem(data);
        // Make sure that the signer is authorized to deposit an item
        // require(signer == operator, "Signature invalid or unauthorized1");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        IERC721Upgradeable(data.itemAddress).transferFrom(
            _msgSender(),
            address(this),
            data.tokenId
        );

        emit DepositItemFromNFTEvent(
            data.id,
            _msgSender(),
            data.itemAddress,
            data.tokenId,
            data.itemType,
            data.extraType,
            uint64(block.timestamp)
        );
    }

    function _verifyDepositItemFromNFT(DepositItemFromNFTStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashDepositItemFromNFT(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashDepositItemFromNFT(DepositItemFromNFTStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "DepositItemFromNFTStruct(string id,address itemAddress,string itemType,string extraType,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.itemAddress,
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.extraType)),
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }
}
