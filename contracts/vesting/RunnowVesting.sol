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

    // uint256 private constant SECONDS_PER_MONTH = 30 days; //mainnet
    uint256 private constant SECONDS_PER_MONTH = 5 minutes; //testnet

    uint256 private constant decimals = 18;

    uint256 public lastestDistributeMonth;

    address public  seedSales;
    address public  privateSales;
    address public  publicSales;
    address public  advisorsAndPartners;
    address public  teamAndOperations;
    address public  mktAndCommunity;
    address public  gameTreasury;
    address public  farmingAndStaking;
    address public  liquidity;

    function initialize() public virtual initializer {
        __vesting_init(
            0xb7b1db1ED12A8DE0fDB16B69844d6b0a3Be47536,
            1657681200,
            0x1357ea29093b7bd4e557D0638F7f3113Dd4D504e,
            0xabD002429daf2A4c383C4491ab968d8Eaeb9AB83,
            0x924db5A9C038A70bD812E403ebc96DF6271e26ba,
            0x2A7A70bDADc13eD9c31069B47d3df46058bDC4f5,
            0xab985ef330f7560B4045D4A1E19A206A36c7479b,
            0xC08c4Fc41F6F63A47E63505f8492fFfD753A2304,
            0x6456be06d125C0B7F661E6E09E695AF4d59D58D1,
            0xeFfe75B1574Bdd2FE0Bc955b57e4f82A2BAD6bF9,
            0x5bc128b3711d741A0DdedD519d55AA60E60f442c
        );
        __Ownable_init();
    }

    function __vesting_init(
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
    ) internal {
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
            "RUNNOWVesting: not claim time"
        );
        uint256 month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        require(
            lastestDistributeMonth <= month,
            "RUNNOWVesting: already claimed in this month"
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
            month <= 36 || (month > 36 && !remainVesting),
            "RUNNOWVesting: expiry time"
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
        uint256 linearAmount = maxAmount  / 12;
        if (month < 3 || month > 14) amount =0;
        else if (month >= 3 && month <= 13) amount = linearAmount;
        else if (month == 14)
            amount = maxAmount - linearAmount * 11;
    }

    function getAmountForPrivateSales(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 40_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount  / 12;
        if (month < 3 || month > 14) amount = 0;
        else if (month >= 3 && month <= 13) amount = linearAmount;
        else if (month == 14)
            amount = maxAmount - linearAmount * 11;
    }

    function getAmountForPublicSales(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 60_000_000 * 10**decimals;
        uint256 publicSaleAmount = 12_000_000 * 10**decimals;
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
        if (month >= 0 && month < 12) amount = 0;
        else if (month >= 12 && month <= 34) amount = linearAmount;
        else if (month == 35) amount = maxAmount - linearAmount * 23;
        else if (month == 36) amount = 0;
    }

    function getAmountForTeamAndOperations(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 200_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 24;
        if (month >= 0 && month < 12 || month >= 36) amount = 0;
        else if (month >= 12 && month <= 34) amount = linearAmount;
        else if (month == 35) amount = maxAmount - linearAmount * 23;
    }

    function getAmountForMktAndCommunity(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 100_000_000 * 10**decimals;
        uint256 publicSaleAmount = 1_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 36;
        if (month > 36) amount = 0;
        else if (month == 0 ) amount = publicSaleAmount;
        else if (month >= 1 && month < 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 35;
    }

    function getAmountForGameTreasury(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 350_000_000 * 10**decimals;
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
        uint256 maxAmount = 150_000_000 * 10**decimals;
        uint256 linearAmount = maxAmount / 36;
        if (month > 36 || month == 0) amount = 0;
        else if (month > 0 && month <= 35) amount = linearAmount;
        else if (month == 36) amount = maxAmount - linearAmount * 35;
    }

    function getAmountForLiquidity(uint256 month)
        public
        view
        returns (uint256 amount)
    {
        uint256 maxAmount = 20_000_000 * 10**decimals;
        uint256 publicSaleAmount = 1_000_000 * 10**decimals;
        uint256 linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0) amount = publicSaleAmount;
        else if (month >= 13) amount = 0;
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
