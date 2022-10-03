// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract IDOClaimUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    struct ClaimStruct {
        uint256 amount;
        address receiver;
        address tokenAddress;
        string[] nonceArray;
        bytes signature;
    }

    event ClaimIDOEvent(
        address indexed user,
        address tokenAddress,
        uint256 amount,
        string[] nonce;
        uint64 timestamp
    );

    event Paused(address account);

    event Unpaused(address account);

    string private constant _SIGNING_DOMAIN = "IDO-Claim-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

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

    modifier checkNonce(string[] calldata nonceArray) {
        for(uint256 i=0;i< nonceArray.length; i++){
            require(!_noncesMap[nonceArray[i]], "The nonce has been used");
        }
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
        checkNonce(claimStruct.nonceArray)
        nonReentrant
    {
        address signer = _verifyClaim(claimStruct)
        require(operator == signer,"Signature invalid or unauthorized");
        require(amount > 0, "Amount must be greater than zero");
        require(IERC20Upgradeable(claimStruct.tokenAddress).balanceOf(address(this))>= claimStruct.amount, "Not enough token");

        IERC20Upgradeable(claimStruct.tokenAddress).transferFrom(
            address(this),
            claimStruct.receiver,
            claimStruct.amount
        );

        emit ClaimIDOEvent(
            claimStruct.receiver,
            claimStruct.tokenAddress,
            claimStruct.amount,
            claimStruct.nonceArray,
            uint64(block.timestamp)
        );
    }

    function _verifyClaim(ClaimStruct calldata claimStruct)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashClaim(data);
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
                            "ClaimStruct(uint256 amount,address receiver,address tokenAddress,string[] nonceArray)"
                        ),
                        claimStruct.amount,
                        claimStruct.receiver,
                        claimStruct.tokenAddress,
                        keccak256(abi.encodePacked(claimStruct.nonceArray))
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
}
