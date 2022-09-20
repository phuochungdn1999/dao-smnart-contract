// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";


contract PublicSalesUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{
    using StringsUpgradeable for uint256;

    event BuyIDOEvent(
        address indexed user,
        address tokenAddress,
        uint256 amount,
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
    }

    function buyIDO(uint256 amount, address tokenAddress)
        public
        whenNotPaused
    {
        require(amount > 0, "Amount must be greater than zero");

        IERC20Upgradeable(tokenAddress).transferFrom(
            _msgSender(),
            fundReceiver,
            amount
        );

        emit BuyIDOEvent(
            _msgSender(),
            tokenAddress,
            amount,
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
