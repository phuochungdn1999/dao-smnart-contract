// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract RUNNOWUpgradeable is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    uint256 public constant cap = 1_000_000_000 * 10**18;
    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    uint256 public _burnAmount;

    function initialize() public virtual initializer {
        __RUNNOW_init();
    }

    function __RUNNOW_init() internal initializer {
        __ERC20_init("RUNNOW", "RUNNOW");
        __Ownable_init();
        __Pausable_init();
        __RUNNOW_init_unchained();
    }

    function __RUNNOW_init_unchained() internal initializer {
        _mint(_msgSender(), 1_000_000 * 10**18);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function setBurnAmount(uint256 _amount) external onlyOwner {
        _burnAmount = _amount;
    }

    function mintBurnToken(address _to) external onlyOwner {
        require(totalSupply() + _burnAmount <= cap, "RUNNOW: Exceed cap"); // Address is zero
        _mint(_to, _burnAmount);
        _burnAmount = 0;
    }
}
