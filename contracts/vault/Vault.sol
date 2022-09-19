// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract MarketplaceV3Upgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable
{

    struct ChargeFeeStruct {
        address walletAddress;
        string id;
        uint256 tokenId;
        uint256 price;
        address tokenAddress;
        address itemAddress;
        string nonce;
        bytes signature;
    }

    event ChargeEvent(
        address user,
        string id,
        uint256 tokenId,
        uint256 price,
        address tokenAddress,
        address itemAddress,
        uint64 timestamp
    );

    event Paused(address account);

    event Unpaused(address account);

    string public constant _SIGNING_DOMAIN = "Vault-Item";
    string private constant _SIGNATURE_VERSION = "1";

    address public feesCollectorAddress;
    address public operator;
    bool private _paused;

    mapping(string => bool) private _noncesMap;

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

    function chagreFee(ChargeFeeStruct calldata data)
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

        emit ChargeEvent(
            _msgSender(),
            data.id,
            data.tokenId,
            data.price,
            data.tokenAddress,
            data.itemAddress,
            uint64(block.timestamp)
        );
    }

    function _verifyChargeFee(ChargeFeeStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashChargeFee(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashChargeFee(ChargeFeeStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ChargeFeeStruct(address walletAddress,string id,uint256 tokenId,uint256 price,address tokenAddress,address itemAddress, string nonce)"
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
}
