import { ethers } from 'hardhat';
import upgradeMarketplaceUpgradeable from './upgradeMarketplace';

const upgradeMarketplaceUpgradeableMain = async (baseAddress: string, version: string = 'MarketplaceUpgradeable') => {
    await upgradeMarketplaceUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradeMarketplaceUpgradeableMain('0x0D51b031cc4CD92560d1F4a94435CF64F7e1d57b');
