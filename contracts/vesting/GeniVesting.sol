pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IGENI.sol";

contract GENIVesting is Ownable {

    address public geni;

    event SetGENI(address geniAddress);
    event SetDistributeTime(uint time);

    uint public distributeTime;

    uint private constant SECONDS_PER_MONTH = 2629743;

    uint public lastestDistributeMonth;

    address public immutable seedSales;
    address public immutable privateSales;
    address public immutable publicSales;
    address public immutable advisorsAndPartners;
    address public immutable teamAndOperations;
    address public immutable mktAndCommunity;
    address public immutable gameTreasury;
    address public immutable farmingAndStaking;
    address public immutable liquidity;

    constructor (
        address geniAddr,
        uint _distributeTime,
        address _seedSales,
        address _privateSales,
        address _publicSales,
        address _advisorsAndPartners,
        address _teamAndOperations,
        address _mktAndCommunity,
        address _gameTreasury,
        address _farmingAndStaking,
        address _liquidity)
    {
        geni = geniAddr;
        distributeTime = _distributeTime;
        require(_privateSales != address(0), "_privateSales cannot be address 0");
        privateSales = _privateSales;
        require(_publicSales != address(0), "_publicSales cannot be address 0");
        publicSales = _publicSales;
        require(_advisorsAndPartners != address(0), "_advisorsAndPartners cannot be address 0");
        advisorsAndPartners = _advisorsAndPartners;
        require(_teamAndOperations != address(0), "_teamAndOperations cannot be address 0");
        teamAndOperations = _teamAndOperations;
        require(_mktAndCommunity != address(0), "_mktAndCommunity cannot be address 0");
        mktAndCommunity = _mktAndCommunity;
        require(_gameTreasury != address(0), "_gameTreasury cannot be address 0");
        gameTreasury = _gameTreasury;
        require(_farmingAndStaking != address(0), "_farmingAndStaking cannot be address 0");
        farmingAndStaking = _farmingAndStaking;
        require(_seedSales != address(0), "_seedSales cannot be address 0");
        seedSales = _seedSales;
        require(_liquidity != address(0), "_liquidity cannot be address 0");
        liquidity = _liquidity;
    }

    function setGeni(address newGeni) external onlyOwner {
        require(address(newGeni) != address(0));
        geni = newGeni;
        emit SetGENI(address(newGeni));
    }

    function setDistributeTime(uint time) external onlyOwner {
        distributeTime = time;
        emit SetDistributeTime(time);
    }

    function distribute() external {
        require(block.timestamp >= distributeTime, "GENIVesting: not claim time");
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        require(lastestDistributeMonth <= month, "GENIVesting: already claimed in this month");

        uint amountForSeedSale;
        uint amountForPrivateSale;
        uint amountForPublicSale;
        uint amountForAdvisorsAndPartners;
        uint amountForTeamAndOperations;
        uint amountForMktAndCommunity;
        uint amountForGameTreasury;
        uint amountForFarmingAndStaking;
        uint amountForLiquidity;

        for (uint i = lastestDistributeMonth; i <= month; i++) {
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
        bool remainVesting = amountForSeedSale == 0 && amountForPrivateSale == 0 && amountForPublicSale == 0 && amountForAdvisorsAndPartners == 0 && amountForTeamAndOperations == 0 && amountForMktAndCommunity == 0 && amountForGameTreasury == 0 && amountForFarmingAndStaking == 0 && amountForLiquidity == 0;
        require(month < 36 || month >= 36 && !remainVesting, "GENIVesting: expiry time");
        if(amountForSeedSale > 0)
            IGENI(geni).mint(seedSales, amountForSeedSale);
        if(amountForPrivateSale > 0)
            IGENI(geni).mint(privateSales, amountForPrivateSale);
        if(amountForPublicSale > 0)
            IGENI(geni).mint(publicSales, amountForPublicSale);
        if(amountForAdvisorsAndPartners > 0)
            IGENI(geni).mint(advisorsAndPartners, amountForAdvisorsAndPartners);
        if(amountForTeamAndOperations > 0)
            IGENI(geni).mint(teamAndOperations, amountForTeamAndOperations);
        if(amountForMktAndCommunity > 0)
            IGENI(geni).mint(mktAndCommunity, amountForMktAndCommunity);
        if(amountForGameTreasury > 0)
            IGENI(geni).mint(gameTreasury, amountForGameTreasury);
        if(amountForFarmingAndStaking > 0)
            IGENI(geni).mint(farmingAndStaking, amountForFarmingAndStaking);
        if(amountForLiquidity > 0)
            IGENI(geni).mint(liquidity, amountForLiquidity);

        lastestDistributeMonth = month + 1;
    }

    function getAmountForSeedSale(uint month) internal view returns (uint amount) {
        uint maxAmount = 5000000 * 10 ** ERC20(geni).decimals();
        uint publicSaleAmount = 250000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0 )
            amount = publicSaleAmount;
        else if (month >= 1 && month <= 6 || month > 18)
            amount = 0;
        else if (month >= 7 && month <= 17 )
            amount = linearAmount;
        else if (month == 18)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getAmountForPrivateSales(uint month) internal view returns (uint amount) {
        uint maxAmount = 10000000  * 10 ** ERC20(geni).decimals();
        uint publicSaleAmount = 500000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = (maxAmount - publicSaleAmount) / 12;
        if (month == 0)
            amount = publicSaleAmount;
        else if (month >= 1 && month <= 6 || month > 18)
            amount = 0;
        else if (month >= 7 && month <= 17 )
            amount = linearAmount;
        else if (month == 18)
            amount = maxAmount - publicSaleAmount - linearAmount * 11;
    }

    function getAmountForPublicSales(uint month) internal view returns (uint amount) {
        uint maxAmount = 2000000  * 10 ** ERC20(geni).decimals();
        if (month == 0)
            amount = maxAmount;
        else if (month > 0)
            amount = 0;
    }

    function getAmountForAdvisorsAndPartners(uint month) internal view returns (uint amount) {
        uint maxAmount = 5000000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = maxAmount / 12;
        if (month >= 0 && month < 12 || month > 23)
            amount = 0;
        else if (month >= 12 && month < 23)
            amount = linearAmount;
        else if (month == 23)
            amount = maxAmount - linearAmount * 11;
    }

    function getAmountForTeamAndOperations(uint month) internal view returns (uint amount) {
        uint maxAmount = 15000000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = maxAmount / 12;
        if  (month >= 0 && month < 12 || month > 23)
            amount = 0;
        else if (month >= 12 && month < 23)
            amount = linearAmount;
        else if(month == 23)
            amount = maxAmount - linearAmount * 11;
    }

    function getAmountForMktAndCommunity(uint month) internal view returns (uint amount) {
        uint maxAmount = 20000000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = maxAmount / 36;
        if (month > 35)
            amount = 0;
        else if (month >= 0 && month < 35)
            amount = linearAmount;
        else if (month == 35)
            amount = maxAmount - linearAmount * 35;
    }

    function getAmountForGameTreasury(uint month) internal view returns (uint amount) {
        uint maxAmount = 23000000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = maxAmount / 36;
        if (month > 35)
            amount = 0;
        else if (month >= 0 && month < 35)
            amount = linearAmount;
        else if (month == 35)
            amount = maxAmount - linearAmount * 35;
    }

    function getAmountForFarmingAndStaking(uint month) internal view returns (uint amount) {
        uint maxAmount = 15000000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = maxAmount / 36;
        if (month > 35)
            amount = 0;
        else if (month >= 0 && month < 35)
            amount = linearAmount;
        else if (month == 35)
            amount = maxAmount - linearAmount * 35;
    }

    function getAmountForLiquidity(uint month) internal view returns (uint amount) {
        uint maxAmount = 5000000 * 10 ** ERC20(geni).decimals();
        uint publicSaleAmount = 500000 * 10 ** ERC20(geni).decimals();
        uint linearAmount = (maxAmount - publicSaleAmount) / 9;
        if (month == 0)
            amount = publicSaleAmount;
        else if (month > 0 && month < 9)
            amount = linearAmount;
        else if (month == 9)
            amount = maxAmount - publicSaleAmount - linearAmount * 8;
        else if (month > 9)
            amount = 0;
    }

    function getDistributeAmountForSeedSale() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForSeedSale;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForSeedSale += getAmountForSeedSale(i);
        }
        return amountForSeedSale;
    }

    function getDistributeAmountForPrivateSales() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForPrivateSale;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForPrivateSale += getAmountForPrivateSales(i);
        }
        return amountForPrivateSale;
    }

    function getDistributeAmountForPublicSales() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForPublicSale;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForPublicSale += getAmountForPublicSales(i);
        }
        return amountForPublicSale;
    }

    function getDistributeAmountForAdvisorsAndPartners() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForAdvisorsAndPartner;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForAdvisorsAndPartner += getAmountForAdvisorsAndPartners(i);
        }
        return amountForAdvisorsAndPartner;
    }

    function getDistributeAmountForTeamAndOperation() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForTeamAndOperations;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForTeamAndOperations += getAmountForTeamAndOperations(i);
        }
        return amountForTeamAndOperations;
    }

    function getDistributeAmountForMktAndCommunity() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForMktAndCommunity;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForMktAndCommunity += getAmountForMktAndCommunity(i);
        }
        return amountForMktAndCommunity;
    }

    function getDistributeAmountForGameTreasury() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForGameTreasury;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
            amountForGameTreasury += getAmountForGameTreasury(i);
        }
        return amountForGameTreasury ;
    }

    function getDistributeAmountForFarmingAndStaking() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForFarmingAndStaking;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
           amountForFarmingAndStaking += getAmountForFarmingAndStaking(i);
        }
        return amountForFarmingAndStaking;
    }

    function getDistributeAmountForLiquidity() external view returns (uint) {
        uint month = (block.timestamp - distributeTime) / SECONDS_PER_MONTH;
        uint amountForLiquidity;
        for (uint i = lastestDistributeMonth; i <= month; i++) {
           amountForLiquidity += getAmountForLiquidity(i);
        }
        return amountForLiquidity;
    }

}
