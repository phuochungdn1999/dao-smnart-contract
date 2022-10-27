// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract VaultUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ChargeTransferFeeStruct {
        address walletAddress;
        string id;
        uint256 tokenId;
        uint256 price;
        address tokenAddress;
        address itemAddress;
        string nonce;
        bytes signature;
    }

    struct TransferNFTStruct {
        string id;
        uint256 tokenId;
        uint256 price;
        uint256 fee;
        address from;
        address to;
        address tokenAddress;
        address nftAddress;
        string nonce;
        bytes signature;
    }

     struct CancelTransferNFTStruct {
        string id;
        uint256 tokenId;
        address owner;
        address nftAddress;
        string nonce;
        bytes signature;
    }

    struct ClaimNFTStruct {
        string id;
        uint256 tokenId;
        uint256 price;
        uint256 fee;
        address from;
        address to;
        address tokenAddress;
        address nftAddress;
        string nonce;
        bytes signature;
    }

    event ChargeFeeEvent(
        address user,
        string id,
        uint256 tokenId,
        uint256 price,
        address tokenAddress,
        address itemAddress,
        uint64 timestamp
    );

    event TransferNFTEvent(
        string indexed id,
        uint256 tokenId,
        uint256 price,
        uint256 fee,
        address from,
        address to,
        address tokenAddress,
        address nftAddress,
        string nonce
    );

    event CancelTransferNFTEvent(
        string indexed id,
        uint256 tokenId,
        address owner,
        address nftAddress,
        string nonce
    );

    event ClaimNFTEvent(
        string indexed id,
        uint256 tokenId,
        uint256 price,
        uint256 fee,
        address from,
        address to,
        address tokenAddress,
        address nftAddress,
        string nonce
    );

    event Paused(address account);

    event Unpaused(address account);

    string public constant _SIGNING_DOMAIN = "Vault-Item";
    string private constant _SIGNATURE_VERSION = "1";

    address public feesCollectorAddress;
    address public operator;
    bool private _paused;

    mapping(string => bool) private _noncesMap;
    mapping(uint256 => address) public senderMap;
    mapping(uint256 => address) public receiverMap;


    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    function initialize() public virtual initializer {
        __Vault_init();
    }

    function __Vault_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();
        __Vault_init_unchained();
    }

    function __Vault_init_unchained() internal initializer {
        feesCollectorAddress = _msgSender();
    }

    function setFeesCollectorAddress(address data) external onlyOwner {
        feesCollectorAddress = data;
    }

    function chargeFeeTransfer(ChargeTransferFeeStruct calldata data)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyChargeFee(data);
        // Make sure that the signer is authorized to charge item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

            uint256 price = data.price;
        if (data.tokenAddress == address(0)) {
            require(
                msg.value == price && price > 0,
                "Not same price or cant be 0"
            );

                (bool success, ) = feesCollectorAddress.call{
                    value: price
                }("");
                require(success, "Transfer fee failed");
        } else {
            require(price > 0, "Price cant be 0");
            // transfer with token
            IERC20Upgradeable(data.tokenAddress).transferFrom(
                _msgSender(),
                feesCollectorAddress,
                price
            );
        }

        emit ChargeFeeEvent(
            _msgSender(),
            data.id,
            data.tokenId,
            data.price,
            data.tokenAddress,
            data.itemAddress,
            uint64(block.timestamp)
        );
    }

    function _verifyChargeFee(ChargeTransferFeeStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashChargeFee(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashChargeFee(ChargeTransferFeeStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ChargeTransferFeeStruct(address walletAddress,string id,uint256 tokenId,uint256 price,address tokenAddress,address itemAddress,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.id)),
                        data.tokenId,
                        data.price,
                        data.tokenAddress,
                        data.itemAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function chargeFeeTransferNFT(TransferNFTStruct calldata data)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyTransferFee(data);
        // Make sure that the signer is authorized to charge item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        require(senderMap[data.tokenId] == address(0),"Already to claim");
        require(data.from != address(0),"Null sender");
        require(data.to != address(0),"Null receiver");
        require(data.nftAddress != address(0),"Invalid NFT");
        require(data.fee <= data.price,"Invalid fee");

        _noncesMap[data.nonce] = true;

        IERC721Upgradeable(data.nftAddress).safeTransferFrom(data.from,address(this),data.tokenId, "");

        senderMap[data.tokenId] = data.from;
        receiverMap[data.tokenId] = data.to;

        emit TransferNFTEvent(
            data.id,
            data.tokenId,
            data.price,
            data.fee,
            data.from,
            data.to,
            data.tokenAddress,
            data.nftAddress,
            data.nonce
        );
    }

    function _verifyTransferFee(TransferNFTStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTransferFee(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashTransferFee(TransferNFTStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "TransferNFTStruct(string id,uint256 tokenId,uint256 price,uint256 fee,address from,address to,address tokenAddress,address nftAddress,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.tokenId,
                        data.price,
                        data.fee,
                        data.from,
                        data.to,
                        data.tokenAddress,
                        data.nftAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function cancelTransferNFT(CancelTransferNFTStruct calldata data)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyCancelTranfer(data);

        // Make sure that the signer is authorized to charge item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        require(data.owner != address(0), "Null owner");
        require(senderMap[data.tokenId] == data.owner, "Invalid owner");
        require(_msgSender() == data.owner,"Invalid caller");
        require(data.nftAddress != address(0), "Invalid NFT");
        require(IERC721Upgradeable(data.nftAddress).ownerOf(data.tokenId) == address(this),"Invalid tokenId");

        _noncesMap[data.nonce] = true;
        senderMap[data.tokenId] = address(0);
        receiverMap[data.tokenId] = address(0);

        IERC721Upgradeable(data.nftAddress).safeTransferFrom(address(this),data.owner,data.tokenId, "");

        emit CancelTransferNFTEvent(
            data.id,
            data.tokenId,
            data.owner,
            data.nftAddress,
            data.nonce
        );
    }

    function _verifyCancelTranfer(CancelTransferNFTStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashCancelTransfer(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashCancelTransfer(CancelTransferNFTStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "CancelTransferNFTStruct(string id,uint256 tokenId,address owner,address nftAddress,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.tokenId,
                        data.owner,
                        data.nftAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function chargeFeeClaimNFT(ClaimNFTStruct calldata data)
        public
        payable
        nonReentrant
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyClaimNFT(data);
        // Make sure that the signer is authorized to charge item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        require(data.nftAddress != address(0), "Invalid NFT");
        require(data.to != address(0), "Invalid receiver");
        require(data.from != address(0), "Invalid sender");
        require(data.nftAddress != address(0), "Invalid NFT address");
        require(IERC721Upgradeable(data.nftAddress).ownerOf(data.tokenId) == address(this),"Invalid tokenId");
        require(receiverMap[data.tokenId] == data.to,"Invalid receiver");
        require(_msgSender() == data.to,"Invalid caller");
        require(data.fee <= data.price,"Invalid fee");

        _noncesMap[data.nonce] = true;

        uint256 price = data.price - data.fee;
        uint256 fee = data.fee;

        if (data.tokenAddress == address(0)) {
            require(msg.value >= data.price, "Not enough money");
            (bool successFee, ) = feesCollectorAddress.call{value: fee}("");
            (bool successPrice, ) = data.from.call{value: price}("");

            require(successFee, "Transfer fee payment failed");
            require(successPrice, "Transfer price payment failed");
        } else {
            IERC20Upgradeable(data.tokenAddress).safeTransferFrom(
                msg.sender,
                feesCollectorAddress,
                fee
            );
            IERC20Upgradeable(data.tokenAddress).safeTransferFrom(
                msg.sender,
                data.from,
                price
            );
        }
        senderMap[data.tokenId] = address(0);
        receiverMap[data.tokenId] = address(0);

        IERC721Upgradeable(data.nftAddress).safeTransferFrom(address(this),data.to,data.tokenId);

        emit ClaimNFTEvent(
            data.id,
            data.tokenId,
            data.price,
            data.fee,
            data.from,
            data.to,
            data.tokenAddress,
            data.nftAddress,
            data.nonce
        );
    }

    function _verifyClaimNFT(ClaimNFTStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashClaimNFT(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashClaimNFT(ClaimNFTStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimNFTStruct(string id,uint256 tokenId,uint256 price,uint256 fee,address from,address to,address tokenAddress,address nftAddress,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.tokenId,
                        data.price,
                        data.fee,
                        data.from,
                        data.to,
                        data.tokenAddress,
                        data.nftAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }


    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function setPause() onlyOwner external whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function setUnpause()onlyOwner external whenPaused {
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
