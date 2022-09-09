// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IBlacklist.sol";
import "../interfaces/IGame.sol";

contract RunnowNFTUpgradeableV2 is
    ERC721Upgradeable,
    OwnableUpgradeable,
    EIP712Upgradeable
{
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    string private baseURI;

    struct ItemVoucherStruct {
        string id;
        string itemType;
        string extraType;
        uint256 price;
        address tokenAddress;
        string nonce;
        bytes signature;
    }

    event RedeemEvent(
        address indexed user,
        string id,
        string itemType,
        string extraType,
        uint256 tokenId,
        string nonce,
        address tokenAddress,
        uint64 timestamp
    );

    struct StarterBoxStruct {
        address walletAddress;
        string id;
        uint256 tokenId;
        uint256 numberTokens;
        string nonce;
        bytes signature;
    }

    struct NanoBoxStruct {
        address walletAddress;
        string id;
        string nonce;
        bytes signatureNFT;
        string itemType;
        string extraType;
        bytes signatureGame;
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

    event OpenStarterBoxEvent(
        address indexed user,
        string id,
        uint256[] tokenIds,
        uint64 timestamp
    );

    event OpenNanoBoxEvent(
        address indexed user,
        string id,
        uint256[] tokenIds,
        uint64 timestamp
    );

    event MintFromGameEvent(
        address indexed user,
        string id,
        string itemType,
        string extraType,
        uint256 tokenId,
        uint64 timestamp
    );

    event Paused(address account);

    event Unpaused(address account);

    string private constant _SIGNING_DOMAIN = "NFT-Voucher";
    string private constant _SIGNATURE_VERSION = "1";

    address public devWalletAddress;
    mapping(string => bool) private _noncesMap;
    CountersUpgradeable.Counter private _tokenIds;

    address public gameAddress;
    address public operator;
    address public banContractAddress;
    address public mintBatchAdress;
    bool private _paused;
    address public mktAddress;


    modifier isBanned(address _user) {
        require(!IBlacklist(banContractAddress).isBanned(_user), "Banned");
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
        __NFT_init();
    }

    function __NFT_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ERC721_init("RunnowNFT", "RunnowNFT");
        __Ownable_init();
        __NFT_init_unchained();
    }

    function __NFT_init_unchained() internal initializer {
        devWalletAddress = _msgSender();
    }

    function setDevWalletAddress(address data) external onlyOwner {
        devWalletAddress = data;
    }

    function setGameAddress(address data) external onlyOwner {
        gameAddress = data;
    }

    function getCurrentId() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function redeem(ItemVoucherStruct calldata data)
        public
        payable
        isBanned(_msgSender())
        whenNotPaused
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyItemVoucher(data);
        // Make sure that the signer is authorized to mint an item
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Transfer payment
        if (data.tokenAddress == address(0)) {
            require(msg.value >= data.price, "Not enough money");
            (bool success, ) = devWalletAddress.call{value: msg.value}("");
            require(success, "Transfer payment failed");
        } else {
            IERC20Upgradeable(data.tokenAddress).transferFrom(
                msg.sender,
                devWalletAddress,
                data.price
            );
        }

        // Mint
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_msgSender(), newTokenId);

        emit RedeemEvent(
            _msgSender(),
            data.id,
            data.itemType,
            data.extraType,
            newTokenId,
            data.nonce,
            data.tokenAddress,
            uint64(block.timestamp)
        );
    }

    function _verifyItemVoucher(ItemVoucherStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashItemVoucher(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashItemVoucher(ItemVoucherStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "ItemVoucherStruct(string id,string itemType,string extraType,uint256 price,address tokenAddress,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        keccak256(bytes(data.itemType)),
                        keccak256(bytes(data.extraType)),
                        data.price,
                        data.tokenAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function openStarterBox(StarterBoxStruct calldata data)
        public
        isBanned(_msgSender())
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyStarterBox(data);
        // Make sure that the signer is authorized to open start box
        require(signer == operator, "Signature invalid or unauthorized");

        // Check nonce & exists token id
        require(_exists(data.tokenId), "Approved query for nonexistent token");
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Mint more tokens
        uint256[] memory tokenIds = new uint256[](data.numberTokens);
        // Reuse token, do not need to burn and create an new one
        tokenIds[0] = data.tokenId;

        for (uint256 i = 1; i < data.numberTokens; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_msgSender(), newTokenId);
            tokenIds[i] = newTokenId;
        }

        emit OpenStarterBoxEvent(
            _msgSender(),
            data.id,
            tokenIds,
            uint64(block.timestamp)
        );
    }

    function _verifyStarterBox(StarterBoxStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashStarterBox(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashStarterBox(StarterBoxStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "StarterBoxStruct(address walletAddress,string id,uint256 tokenId,uint256 numberTokens,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.id)),
                        data.tokenId,
                        data.numberTokens,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function mintFromGame(
        address to,
        string calldata id,
        string calldata itemType,
        string calldata extraType
    ) external returns (uint256) {
        require(_msgSender() == gameAddress, "Unauthorized");
        require(!IBlacklist(banContractAddress).isBanned(to), "Banned");

        // Mint
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);

        emit MintFromGameEvent(
            to,
            id,
            itemType,
            extraType,
            newTokenId,
            uint64(block.timestamp)
        );

        return newTokenId;
    }

    function mintFromGameAndBringToGame(
        address to,
        string calldata id,
        string calldata itemType,
        string calldata extraType
    ) external returns (uint256) {
        require(_msgSender() == gameAddress, "Unauthorized");
        require(!IBlacklist(banContractAddress).isBanned(to), "Banned");

        // Mint
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(gameAddress, newTokenId);

        emit MintFromGameEvent(
            to,
            id,
            itemType,
            extraType,
            newTokenId,
            uint64(block.timestamp)
        );

        return newTokenId;
    }

    function mintBatch(
        address[] calldata to,
        string[] calldata ids,
        string[] calldata itemTypes,
        string[] calldata extraTypes,
        string[] calldata nonces
    ) external whenNotPaused {
        require(_msgSender() == mintBatchAdress, "Unauthorized");
        require(
            to.length == ids.length &&
                ids.length == itemTypes.length &&
                itemTypes.length == extraTypes.length &&
                nonces.length == extraTypes.length,
            "Array invalid"
        );
        require(to.length <= 150, "Over 150");

        // for loop Mint
        for (uint256 i = 0; i < to.length; i++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(to[i], newTokenId);

            emit RedeemEvent(
                to[i],
                ids[i],
                itemTypes[i],
                extraTypes[i],
                newTokenId,
                nonces[i],
                address(0),
                uint64(block.timestamp)
            );
        }
    }

    function setBaseURI(string memory _baseUri) external {
        baseURI = _baseUri;
    }

    function burn(uint256 tokenId) external returns (uint256) {
        //burn tokenId
        require(ownerOf(tokenId) == msg.sender, "Not owner of NFT");
        _burn(tokenId);

        return tokenId;
    }

    function setOperator(address _operator) external onlyOwner {
        operator = _operator;
    }

    function setBanContractAddress(address data) external onlyOwner {
        banContractAddress = data;
    }

    function setMintBatchAdress(address data) external onlyOwner {
        mintBatchAdress = data;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function setMarketplaceAddress(address data) external onlyOwner {
        mktAddress = data;
    }

    function setPause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function setUnpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    function openNanoBox(NanoBoxStruct calldata data)
        public
        isBanned(_msgSender())
    {
        // Make sure signature is valid and get the address of the signer
        address signer = _verifyNanoBox(data);
        // Make sure that the signer is authorized to open start box
        require(signer == operator, "Signature invalid or unauthorized");

        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        // Mint sneaker nano and medal
        uint256[] memory tokenIds = new uint256[](2);

        //Mint sneaker
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(address(this), newTokenId);
        tokenIds[0] = newTokenId;
        _approve(gameAddress, newTokenId);

        //  depositItem;
        IGame.DepositItemFromNFTStruct memory depositItem = IGame
            .DepositItemFromNFTStruct(
                data.id,
                address(this),
                newTokenId,
                data.itemType,
                data.extraType,
                data.nonce,
                data.signatureGame
            );

        //Mint medal
        _tokenIds.increment();
        newTokenId = _tokenIds.current();
        _mint(_msgSender(), newTokenId);
        tokenIds[1] = newTokenId;

        emit OpenNanoBoxEvent(
            _msgSender(),
            data.id,
            tokenIds,
            uint64(block.timestamp)
        );
        IGame(gameAddress).depositItemFromNFT(depositItem);
    }

    function _verifyNanoBox(NanoBoxStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashNanoBox(data);
        return ECDSAUpgradeable.recover(digest, data.signatureNFT);
    }

    function _hashNanoBox(NanoBoxStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NanoBoxStruct(address walletAddress,string id,string nonce)"
                        ),
                        _msgSender(),
                        keccak256(bytes(data.id)),
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 tokenId
    // ) public virtual override {
    //     //solhint-disable-next-line max-line-length
    //     require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
    //     require(_msgSender() == gameAddress || _msgSender() == mktAddress,"Address not allow to transfer");

    //     _transfer(from, to, tokenId);
    // }
}
