// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NFTUpgradeable is
    ERC721Upgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string private constant SIGNING_DOMAIN = "NFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";

    address public devWallet;
    mapping(address => bool) private _operators;
    mapping(address => mapping(string => bool)) private _usedNonce;
    CountersUpgradeable.Counter private _tokenIds;

    struct NFTVoucher {
        address redeemer;
        string itemId;
        string itemClass;
        uint256 coinPrice;
        uint256 tokenPrice;
        address tokenAddress;
        string nonce;
        bytes signature;
    }

    struct StarterBox {
        address redeemer;
        string boxId;
        uint256 boxTokenId;
        uint256 numberTokens;
        string nonce;
        bytes signature;
    }

    event Redeem(
        address indexed from,
        uint256 tokenId,
        NFTVoucher voucher,
        uint64 timestamp
    );

    event MintedStarterBox(
        address indexed from,
        string boxId,
        uint256[] tokenIds,
        uint64 timestamp
    );

    function initialize() public virtual initializer {
        __ZODIBONFT_init();
    }

    function __ZODIBONFT_init() internal initializer {
        __EIP712_init(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __ERC721_init("ZODIBONFT", "ZODIBONFT");
        __Ownable_init();
        __ZODIBONFT_init_unchained();
    }

    function __ZODIBONFT_init_unchained() internal initializer {
        _operators[_msgSender()] = true;
        devWallet = _msgSender();
    }

    modifier hasPrivilege(address msgSender) {
        require(_operators[msgSender], "You don't have privilege");
        _;
    }

    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "Invalid operator");
        _operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        require(_operators[operator], "You're not operator");
        _operators[operator] = false;
    }

    function setDevWallet(address newDevWallet) external onlyOwner {
        devWallet = newDevWallet;
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function redeem(NFTVoucher calldata data) public payable {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyNFTVoucher(data);
        // Make sure that the signer is authorized to mint NFTs
        require(signer == owner(), "Signature invalid or unauthorized");

        // Check nonce
        require(
            !_usedNonce[_msgSender()][data.nonce],
            "The nonce has been used"
        );
        _usedNonce[_msgSender()][data.nonce] = true;

        // Transfer payment
        if (msg.value > 0 && data.coinPrice > 0) {
            require(msg.value >= data.coinPrice, "Not enough money");
            payable(devWallet).transfer(msg.value);
        } else if (data.tokenPrice > 0) {
            ERC20Upgradeable(data.tokenAddress).transferFrom(
                _msgSender(),
                devWallet,
                data.tokenPrice
            );
        }

        // Mint token
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_msgSender(), newTokenId);

        emit Redeem(_msgSender(), newTokenId, data, uint64(block.timestamp));
    }

    function _verifyNFTVoucher(NFTVoucher calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashVoucher(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashVoucher(NFTVoucher calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(address redeemer,string itemId,string itemClass,uint256 coinPrice,uint256 tokenPrice,address tokenAddress,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.itemId)),
                        keccak256(bytes(data.itemClass)),
                        data.coinPrice,
                        data.tokenPrice,
                        data.tokenAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function openStarterBox(StarterBox calldata data) public {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyStarterBox(data);
        // Make sure that the signer is authorized to mint NFTs
        require(signer == owner(), "Signature invalid or unauthorized");

        // Check nonce & exists token id
        require(
            _exists(data.boxTokenId),
            "Approved query for nonexistent token"
        );
        require(
            !_usedNonce[_msgSender()][data.nonce],
            "The nonce has been used"
        );
        _usedNonce[_msgSender()][data.nonce] = true;

        // Mint more tokens
        uint256[] memory tokenIds = new uint256[](data.numberTokens);
        // Reuse token, do not need to burn and create an new one
        tokenIds[0] = data.boxTokenId;

        for (uint256 i = 1; i < data.numberTokens; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_msgSender(), newTokenId);
            tokenIds[i] = newTokenId;
        }

        emit MintedStarterBox(
            _msgSender(),
            data.boxId,
            tokenIds,
            uint64(block.timestamp)
        );
    }

    function _verifyStarterBox(StarterBox calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashStarterBox(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashStarterBox(StarterBox calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "StarterBox(address redeemer,string boxId,uint256 boxTokenId,uint256 numberTokens,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.boxId)),
                        data.boxTokenId,
                        data.numberTokens,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }
}
