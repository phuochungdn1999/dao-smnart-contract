// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IRunnow.sol";

contract VestingUpgradeable is OwnableUpgradeable {
    address public runnow;

    event SetRUNNOW(address geniAddress);
    event SetDistributeTime(uint256 time);

    uint256 public distributeTime;

    uint256 private constant SECONDS_PER_MONTH = 30 days;

    uint256 private constant decimals = 18;

    uint256 public lastestDistributeMonth;

    address public immutable seedSales;
    address public immutable privateSales;
    address public immutable publicSales;
    address public immutable advisorsAndPartners;
    address public immutable teamAndOperations;
    address public immutable mktAndCommunity;
    address public immutable gameTreasury;
    address public immutable farmingAndStaking;
    address public immutable liquidity;

    constructor(
        address _runnowAddr,
        uint256 _distributeTime,
        address _seedSales,
        address _privateSales,
        address _publicSales,
        address _advisorsAndPartners,
        address _teamAndOperations,
        address _mktAndCommunity,
        address _gameTreasury,
        address _farmingAndStaking,
        address _liquidity
    ) {
        runnow = _runnowAddr;
        distributeTime = _distributeTime;
        require(
            _privateSales != address(0),
            "_privateSales cannot be address 0"
        );
        privateSales = _privateSales;
        require(_publicSales != address(0), "_publicSales cannot be address 0");
        publicSales = _publicSales;
        require(
            _advisorsAndPartners != address(0),
            "_advisorsAndPartners cannot be address 0"
        );
        advisorsAndPartners = _advisorsAndPartners;
        require(
            _teamAndOperations != address(0),
            "_teamAndOperations cannot be address 0"
        );
        teamAndOperations = _teamAndOperations;
        require(
            _mktAndCommunity != address(0),
            "_mktAndCommunity cannot be address 0"
        );
        mktAndCommunity = _mktAndCommunity;
        require(
            _gameTreasury != address(0),
            "_gameTreasury cannot be address 0"
        );
        gameTreasury = _gameTreasury;
        require(
            _farmingAndStaking != address(0),
            "_farmingAndStaking cannot be address 0"
        );
        farmingAndStaking = _farmingAndStaking;
        require(_seedSales != address(0), "_seedSales cannot be address 0");
        seedSales = _seedSales;
        require(_liquidity != address(0), "_liquidity cannot be address 0");
        liquidity = _liquidity;
    }

    function setRunnow(address newRunnow) external onlyOwner {
        require(address(newRunnow) != address(0));
        runnow = newRunnow;
        emit SetRUNNOW(address(newRunnow));
    }

    function setDistributeTime(uint256 time) external onlyOwner {
        distributeTime = time;
        emit SetDistributeTime(time);
    }

    function distribute() external {
        require(
            block.timestamp >= distributeTime,
            "GENIVesting: not claim time"
        );
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        require(
            lastestDistributeMonth <= month,
            "GENIVesting: already claimed in this month"
        );

        uint256 amountForSeedSale;
        uint256 amountForPrivateSale;
        uint256 amountForPublicSale;
        uint256 amountForAdvisorsAndPartners;
        uint256 amountForTeamAndOperations;
        uint256 amountForMktAndCommunity;
        uint256 amountForGameTreasury;
        uint256 amountForFarmingAndStaking;
        uint256 amountForLiquidity;

        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForPrivateSale += getAmountForPrivateSales(i);
            amountForPublicSale += getAmountForPublicSales(i);
            amountForAdvisorsAndPartners += getAmountForAdvisorsAndPartners(i);
            amountForTeamAndOperations += getAmountForTeamAndOperations(i);
            amountForMktAndCommunity += getAmountForMktAndCommunity(i);
            amountForGameTreasury += getAmountForGameTreasury(i);
            amountForFarmingAndStaking += getAmountForFarmingAndStaking(i);
            amountForSeedSale += getAmountForSeedSale(i);
            amountForLiquidity += getAmountForLiquidity(i);
        }
        bool remainVesting = amountForSeedSale == 0 &&
            amountForPrivateSale == 0 &&
            amountForPublicSale == 0 &&
            amountForAdvisorsAndPartners == 0 &&
            amountForTeamAndOperations == 0 &&
            amountForMktAndCommunity == 0 &&
            amountForGameTreasury == 0 &&
            amountForFarmingAndStaking == 0 &&
            amountForLiquidity == 0;
        require(
            month < 36 || (month >= 36 && !remainVesting),
            "GENIVesting: expiry time"
        );
        if (amountForSeedSale > 0)
            IRunnow(runnow).mint(seedSales, amountForSeedSale);
        if (amountForPrivateSale > 0)
            IRunnow(runnow).mint(privateSales, amountForPrivateSale);
        if (amountForPublicSale > 0)
            IRunnow(runnow).mint(publicSales, amountForPublicSale);
        if (amountForAdvisorsAndPartners > 0)
            IRunnow(runnow).mint(
                advisorsAndPartners,
                amountForAdvisorsAndPartners
            );
        if (amountForTeamAndOperations > 0)
            IRunnow(runnow).mint(teamAndOperations, amountForTeamAndOperations);
        if (amountForMktAndCommunity > 0)
            IRunnow(runnow).mint(mktAndCommunity, amountForMktAndCommunity);
        if (amountForGameTreasury > 0)
            IRunnow(runnow).mint(gameTreasury, amountForGameTreasury);
        if (amountForFarmingAndStaking > 0)
            IRunnow(runnow).mint(farmingAndStaking, amountForFarmingAndStaking);
        if (amountForLiquidity > 0)
            IRunnow(runnow).mint(liquidity, amountForLiquidity);

        lastestDistributeMonth = month + 1;
    }

    function getAmountForSeedSale(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 30_000_000 * 10**decimals;
        uint256 publicSaleAmount = 1_200_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0) amount = publicSaleAmount;
        else if ((month >= 1 && month <= 3) || month > 15) amount = 0;
        else if (month >= 4 && month <= 14) amount = linearAmount;
        else if (month == 15)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getAmountForPrivateSales(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 40_000_000 * 10**decimals;
        uint256 publicSaleAmount = 1_600_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0) amount = publicSaleAmount;
        else if ((month >= 1 && month <= 3) || month > 15) amount = 0;
        else if (month >= 4 && month <= 14) amount = linearAmount;
        else if (month == 15)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getAmountForPublicSales(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 30_000_000 * 10**decimals;
        uint256 publicSaleAmount = 7_500_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 3;
        if (month == 0) amount = publicSaleAmount;
        else if (month == 1 || month > 4) amount = 0;
        else if (month == 2 || month == 3) amount = linearAmount;
        else if (month == 4)
            amount = maxAmount - publicSaleAmount - linearAmount * 2;
    }

    function getAmountForAdvisorsAndPartners(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 50_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 24;
        if (month >= 0 && month <= 12) amount = 0;
        else if (month >= 13 && month <= 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 23;
    }

    function getAmountForTeamAndOperations(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 200_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 24;
        if (month >= 0 && month <= 12) amount = 0;
        else if (month >= 13 && month <= 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 23;
    }

    function getAmountForMktAndCommunity(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 150_000_000 * 10**decimals;
        uint256 publicSaleAmount = 1_500_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 36;
        if (month > 36) amount = 0;
        else if (month >= 0 && month < 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 35;
    }

    function getAmountForGameTreasury(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 400_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 36;
        if (month > 36 || month == 0) amount = 0;
        else if (month >= 1 && month < 36) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 35;
    }

    function getAmountForFarmingAndStaking(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 50_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 36;
        if (month > 36 || month == 0) amount = 0;
        else if (month >= 0 && month < 35) amount = linearAmount;
        else if (month == 35) amount = maxAmount - linearAmount * 35;
    }

    function getAmountForLiquidity(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 50_000_000 * 10**decimals;
        uint256 publicSaleAmount = 2_500_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0) amount = publicSaleAmount;
        else if ((month >= 13) || month > 15) amount = 0;
        else if (month >= 1 && month <= 11) amount = linearAmount;
        else if (month == 12)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getDistributeAmountForSeedSale() external view returns (uint256) {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForSeedSale;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForSeedSale += getAmountForSeedSale(i);
        }
        return amountForSeedSale;
    }

    function getDistributeAmountForPrivateSales()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForPrivateSale;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForPrivateSale += getAmountForPrivateSales(i);
        }
        return amountForPrivateSale;
    }

    function getDistributeAmountForPublicSales()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForPublicSale;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForPublicSale += getAmountForPublicSales(i);
        }
        return amountForPublicSale;
    }

    function getDistributeAmountForAdvisorsAndPartners()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForAdvisorsAndPartner;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForAdvisorsAndPartner += getAmountForAdvisorsAndPartners(i);
        }
        return amountForAdvisorsAndPartner;
    }

    function getDistributeAmountForTeamAndOperation()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForTeamAndOperations;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForTeamAndOperations += getAmountForTeamAndOperations(i);
        }
        return amountForTeamAndOperations;
    }

    function getDistributeAmountForMktAndCommunity()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForMktAndCommunity;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForMktAndCommunity += getAmountForMktAndCommunity(i);
        }
        return amountForMktAndCommunity;
    }

    function getDistributeAmountForGameTreasury()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForGameTreasury;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForGameTreasury += getAmountForGameTreasury(i);
        }
        return amountForGameTreasury;
    }

    function getDistributeAmountForFarmingAndStaking()
        external
        view
        returns (uint256)
    {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForFarmingAndStaking;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForFarmingAndStaking += getAmountForFarmingAndStaking(i);
        }
        return amountForFarmingAndStaking;
    }

    function getDistributeAmountForLiquidity() external view returns (uint256) {
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint256 amountForLiquidity;
        for (uint256 i = lastestDistributeMonth; i <= month; i++) {
            amountForLiquidity += getAmountForLiquidity(i);
        }
        return amountForLiquidity;
    }

    function setNewRunnowOwnership(address newRunnow) external onlyOwner {
        require(address(newRunnow) != address(0));
        IRunnow(runnow).transferOwnership(newRunnow);
        // emit SetRUNNOW(address(newRunnow));
    }
}
