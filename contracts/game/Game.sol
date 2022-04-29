// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../nft/NFTV2.sol";

contract GameUpgradeable is OwnableUpgradeable, EIP712Upgradeable {
    struct WithdrawTokenVoucherStruct {
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
        address indexed token,
        uint256 amount,
        uint64 timestamp
    );

    event DepositItemEvent(
        address indexed user,
        address indexed token,
        uint256 tokenId,
        string itemType,
        uint64 timestamp
    );

    struct WithdrawItemVoucherStruct {
        string id;
        address tokenAddress;
        uint256 tokenId;
        string itemType;
        string nonce;
        bytes signature;
    }

    event WithdrawItemEvent(
        string id,
        address indexed user,
        string itemType,
        string nonce,
        uint64 timestamp
    );

    string private constant _SIGNING_DOMAIN = "NFT-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

    mapping(string => bool) private _noncesMap;

    function initialize() public virtual initializer {
        __Game_init();
    }

    function __Game_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __Ownable_init();
        __Game_init_unchained();
    }

    function __Game_init_unchained() internal initializer {}

    function depositToken(address token, uint256 amount) public {
        require(amount > 0, "Amount must greater than zero");
        IERC20Upgradeable(token).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        emit DepositTokenEvent(
            _msgSender(),
            token,
            amount,
            uint64(block.timestamp)
        );
    }

    function withdrawToken(WithdrawTokenVoucherStruct calldata voucher) public {
        // make sure nonce is not used (tx is not used)
        require(!_noncesMap[voucher.nonce], "Nonce has used");
        _noncesMap[voucher.nonce] = true;

        // make sure signature is valid and get the address of the signer
        address signer = _verifyWithdrawToken(voucher);
        // make sure that the signer is authorized
        require(signer == owner(), "Signature invalid or unauthorized");

        IERC20Upgradeable(voucher.tokenAddress).transfer(
            _msgSender(),
            voucher.amount
        );
        emit WithdrawTokenEvent(
            _msgSender(),
            voucher.nonce,
            uint64(block.timestamp)
        );
    }

    function _verifyWithdrawToken(WithdrawTokenVoucherStruct calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashWithdrawToken(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hashWithdrawToken(WithdrawTokenVoucherStruct calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WithdrawTokenVoucherStruct(address tokenAddress,uint256 amount,string nonce)"
                        ),
                        voucher.tokenAddress,
                        voucher.amount,
                        keccak256(bytes(voucher.nonce))
                    )
                )
            );
    }

    function depositItem(
        address token,
        uint256 tokenId,
        string calldata itemType
    ) public {
        IERC721Upgradeable(token).transferFrom(
            _msgSender(),
            address(this),
            tokenId
        );

        emit DepositItemEvent(
            _msgSender(),
            token,
            tokenId,
            itemType,
            uint64(block.timestamp)
        );
    }

    function withdrawItem(WithdrawItemVoucherStruct calldata voucher) public {
        // make sure nonce is not used (tx is not used)
        require(!_noncesMap[voucher.nonce], "Nonce has used");
        _noncesMap[voucher.nonce] = true;

        // make sure signature is valid and get the address of the signer
        address signer = _verifyWithdrawItem(voucher);
        // make sure that the signer is authorized
        require(signer == owner(), "Signature invalid or unauthorized");

        if (voucher.tokenId == 0) {
            NFTUpgradeableV2(voucher.tokenAddress).redeemCraftItem(
                _msgSender(),
                voucher.itemType,
                voucher.nonce
            );
        } else {
            // transfer from game to withdrawer
            IERC721Upgradeable(voucher.tokenAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                voucher.tokenId
            );

            emit WithdrawItemEvent(
                voucher.id,
                _msgSender(),
                voucher.itemType,
                voucher.nonce,
                uint64(block.timestamp)
            );
        }
    }

    function _verifyWithdrawItem(WithdrawItemVoucherStruct calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashWithdrawItem(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hashWithdrawItem(WithdrawItemVoucherStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WithdrawItemVoucherStruct(string id,address tokenAddress,uint256 tokenId,string itemType,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.tokenAddress,
                        data.tokenId,
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }
}
