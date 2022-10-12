// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract IDOClaimUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct ClaimStruct {
        uint256 amount;
        uint256[] month;
        address receiver;
        address tokenAddress;
        string nonce;
        bytes signature;
    }

    event ClaimIDOEvent(
        address indexed user,
        address tokenAddress,
        uint256 amount,
        uint256[] month,
        string nonce,
        uint64 timestamp
    );

    event Paused(address account);

    event Unpaused(address account);

    string private constant _SIGNING_DOMAIN = "IDO-Claim-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

    mapping(address => mapping(uint256 => bool)) private _monthsMap;
    mapping(string => bool) private _noncesMap;

    address public operator;

    bool private _paused;

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier checkMonthAndNonce(
        uint256[] calldata month,
        string calldata nonce
    ) {
        for (uint256 i = 0; i < month.length; i++) {
            require(
                !_monthsMap[_msgSender()][month[i]],
                "Month already withdraw"
            );
            _monthsMap[_msgSender()][month[i]] = true;
        }
        require(!_noncesMap[nonce], "nonce already used");

        _;
    }

    function initialize() public virtual initializer {
        __IDOClaim_init();
    }

    function __IDOClaim_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ReentrancyGuard_init();
        __Ownable_init();
        __IDOClaim_init_unchained();
    }

    function __IDOClaim_init_unchained() internal initializer {
        operator = _msgSender();
    }

    function claimIDO(ClaimStruct calldata claimStruct)
        public
        whenNotPaused
        nonReentrant
        checkMonthAndNonce(claimStruct.month, claimStruct.nonce)
    {
        address signer = _verifyClaim(claimStruct);
        require(operator == signer, "Signature invalid or unauthorized");
        require(_msgSender() == claimStruct.receiver, "Wrong caller");
        require(claimStruct.amount > 0, "Amount must be greater than zero");
        require(
            IERC20Upgradeable(claimStruct.tokenAddress).balanceOf(
                address(this)
            ) >= claimStruct.amount,
            "Not enough token"
        );

        _noncesMap[claimStruct.nonce] = true;
        for (uint256 i = 0; i < claimStruct.month.length; i++) {
            _monthsMap[_msgSender()][claimStruct.month[i]] = true;
        }

        IERC20Upgradeable(claimStruct.tokenAddress).safeTransfer(
            claimStruct.receiver,
            claimStruct.amount
        );

        emit ClaimIDOEvent(
            claimStruct.receiver,
            claimStruct.tokenAddress,
            claimStruct.amount,
            claimStruct.month,
            claimStruct.nonce,
            uint64(block.timestamp)
        );
    }

    function _verifyClaim(ClaimStruct calldata claimStruct)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashClaim(claimStruct);
        return ECDSAUpgradeable.recover(digest, claimStruct.signature);
    }

    function _hashClaim(ClaimStruct calldata claimStruct)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ClaimStruct(uint256 amount,uint256[] month,address receiver,address tokenAddress,string nonce)"
                        ),
                        claimStruct.amount,
                        keccak256(abi.encodePacked(claimStruct.month)),
                        claimStruct.receiver,
                        claimStruct.tokenAddress,
                        keccak256(bytes(claimStruct.nonce))
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

    function setPause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function setUnpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function withdrawToken(address _token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance > 0, "Invalid amount");
        IERC20Upgradeable(_token).transfer(_msgSender(), balance);
    }
}
