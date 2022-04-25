import { ethers, upgrades } from 'hardhat';

const deployMarketplaceUpgradeable = async () => {
    const accounts = await ethers.getSigners();
    const upgradeableFactory = await ethers.getContractFactory("MarketplaceUpgradeable", accounts[0]);
    const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
    await proxyInstance.deployed();
    console.log("MarketplaceUpgradeable: ", proxyInstance.address);
    return proxyInstance;
};

export default deployMarketplaceUpgradeable;
