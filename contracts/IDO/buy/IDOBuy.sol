// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


contract IDOBuyUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct BuyStruct {
        uint256 amount;
        address receiver;
        address tokenAddress;
        string nonce;
        bytes signature;
    }

    event BuyIDOEvent(
        address indexed user,
        address tokenAddress,
        uint256 amount,
        string nonce,
        uint64 timestamp
    );

    event Paused(address account);

    event Unpaused(address account);

    string private constant _SIGNING_DOMAIN = "IDO-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

    mapping(string => bool) private _noncesMap;

    address public operator;
    address public fundReceiver;

    bool private _paused;

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    function initialize() public virtual initializer {
        __PublicSale_init();
    }

    function __PublicSale_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();
        __PublicSale_init_unchained();
    }

    function __PublicSale_init_unchained() internal initializer {
        fundReceiver = _msgSender();
        operator = _msgSender();
    }

    function _verifyBuy(BuyStruct calldata buyStruct)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashBuy(buyStruct);
        return ECDSAUpgradeable.recover(digest, buyStruct.signature);
    }

    function _hashBuy(BuyStruct calldata buyStruct)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BuyStruct(uint256 amount,address receiver,address tokenAddress,string nonce)"
                        ),
                        buyStruct.amount,
                        _msgSender(),
                        buyStruct.tokenAddress,
                        keccak256(bytes(buyStruct.nonce))
                    )
                )
            );
    }

    function buyIDO(BuyStruct calldata buyStruct)
        public
        whenNotPaused
    {
        address signer = _verifyBuy(buyStruct);
        require(signer == operator,"Signature invalid or unauthorized");
        require(buyStruct.amount > 0, "Amount must be greater than zero");
        require(!_noncesMap[buyStruct.nonce],"nonce already used");
        _noncesMap[buyStruct.nonce] = true;

        IERC20Upgradeable(buyStruct.tokenAddress).safeTransferFrom(
            _msgSender(),
            fundReceiver,
            buyStruct.amount
        );

        emit BuyIDOEvent(
            _msgSender(),
            buyStruct.tokenAddress,
            buyStruct.amount,
            buyStruct.nonce,
            uint64(block.timestamp)
        );
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setFundReceiver(address _fundReceiver) external onlyOwner {
        fundReceiver = _fundReceiver;
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
}
