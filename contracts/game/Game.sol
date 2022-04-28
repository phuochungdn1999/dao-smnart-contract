// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract GameUpgradeable is OwnableUpgradeable, EIP712Upgradeable {
    string private constant SIGNING_DOMAIN = "NFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    mapping(string => bool) private _noncesMap;

    struct WithdrawVoucher {
        address withdrawer;
        address token;
        uint256 tokenId;
        string nonce;
        bytes signature;
    }

    struct WithdrawTokenVoucher {
        address withdrawer;
        address tokenAddress;
        uint256 amount;
        string nonce;
        bytes signature;
    }

    event DepositNFT(
        address indexed user,
        address indexed token,
        uint256 tokenId,
        uint64 timestamp
    );

    event WithdrawNFT(
        address indexed user,
        WithdrawVoucher voucher,
        uint64 timestamp
    );

    event DepositToken(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint64 timestamp
    );

    event WithdrawToken(
        address indexed user,
        WithdrawTokenVoucher voucher,
        uint64 timestamp
    );

    function initialize() public virtual initializer {
        __Game_init();
    }

    function __Game_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
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
        emit DepositToken(_msgSender(), token, amount, uint64(block.timestamp));
    }

    function withdrawToken(WithdrawTokenVoucher calldata voucher) public {
        // make sure nonce is not used (tx is not used)
        require(!_noncesMap[voucher.nonce], "Nonce has used");
        _noncesMap[voucher.nonce] = true;

        // make sure signature is valid and get the address of the signer
        address signer = _verifyWithdrawToken(voucher);
        // make sure that the signer is authorized
        require(signer == owner(), "Signature invalid or unauthorized");

        IERC20Upgradeable(voucher.tokenAddress).transfer(
            voucher.withdrawer,
            voucher.amount
        );
        emit WithdrawToken(
            voucher.withdrawer,
            voucher,
            uint64(block.timestamp)
        );
    }

    function depositNFT(address token, uint256 tokenId) public {
        IERC721Upgradeable(token).transferFrom(
            _msgSender(),
            address(this),
            tokenId
        );

        emit DepositNFT(_msgSender(), token, tokenId, uint64(block.timestamp));
    }

    function withdrawNFT(WithdrawVoucher calldata voucher) public {
        // make sure nonce is not used (tx is not used)
        require(!_noncesMap[voucher.nonce], "Nonce has used");
        _noncesMap[voucher.nonce] = true;

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        // make sure that the signer is authorized
        require(signer == owner(), "Signature invalid or unauthorized");

        // transfer from game to withdrawer
        IERC721Upgradeable(voucher.token).safeTransferFrom(
            address(this),
            voucher.withdrawer,
            voucher.tokenId
        );

        emit WithdrawNFT(_msgSender(), voucher, uint64(block.timestamp));
    }

    function _verify(WithdrawVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hash(WithdrawVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WithdrawVoucher(address withdrawer,address token,uint256 tokenId,string nonce)"
                        ),
                        voucher.withdrawer,
                        voucher.token,
                        voucher.tokenId,
                        keccak256(bytes(voucher.nonce))
                    )
                )
            );
    }

    function _verifyWithdrawToken(WithdrawTokenVoucher calldata voucher)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashWithdrawToken(voucher);
        return ECDSAUpgradeable.recover(digest, voucher.signature);
    }

    function _hashWithdrawToken(WithdrawTokenVoucher calldata voucher)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "WithdrawTokenVoucher(address withdrawer,address tokenAddress,uint256 amount,string nonce)"
                        ),
                        voucher.withdrawer,
                        voucher.tokenAddress,
                        voucher.amount,
                        keccak256(bytes(voucher.nonce))
                    )
                )
            );
    }
}
