import { ethers } from 'hardhat';
import upgradeMarketplaceUpgradeable from './upgradeMarketplace';

const upgradeMarketplaceUpgradeableMain = async (baseAddress: string, version: string = 'MarketplaceUpgradeable') => {
    await upgradeMarketplaceUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradeMarketplaceUpgradeableMain('0x9E8dfbF4a679B836D5F3f075780920bB1d8c3c49');
