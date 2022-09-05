// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

contract BlacklistUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable
{

    event Blacklist(
        address indexed user,
        bool indexed isBanned
    );


    string private constant _SIGNING_DOMAIN = "Blacklist-Voucher";
    string private constant _SIGNATURE_VERSION = "1";
    uint256 public MAX_USERS_BAN;

    mapping(address => bool) private blacklist;

    function initialize() public virtual initializer {
        __Blacklist_init();
    }

    function __Blacklist_init() internal initializer {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __Ownable_init();
        __Blacklist_init_unchained();
    }

    function __Blacklist_init_unchained() internal initializer {
        MAX_USERS_BAN = 500;
    }

    function isBanned(address _user) external view returns(bool){
        return blacklist[_user];
    }

    function setBlacklist(address[] memory _arrayUsers)external onlyOwner returns(bool){
        require(_arrayUsers.length <= MAX_USERS_BAN, "Too much");
        for(uint256 i=0; i< _arrayUsers.length;i++){
            require(_arrayUsers[i] != address(0), "Null address");
            blacklist[_arrayUsers[i]] = true;
            emit Blacklist(_arrayUsers[i],true);
        }
    }

    function removeBlacklist(address[] memory _arrayUsers)external onlyOwner returns(bool){
        require(_arrayUsers.length <= MAX_USERS_BAN, "Too much");
        for(uint256 i=0; i< _arrayUsers.length;i++){
            require(_arrayUsers[i] != address(0), "Null address");
            blacklist[_arrayUsers[i]] = false;
            emit Blacklist(_arrayUsers[i],false);
        }
    }


}
