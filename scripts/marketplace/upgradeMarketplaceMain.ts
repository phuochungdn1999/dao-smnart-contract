import { ethers } from 'hardhat';
import upgradeMarketplaceUpgradeable from './upgradeMarketplace';

const upgradeMarketplaceUpgradeableMain = async (baseAddress: string, version: string = 'MarketplaceUpgradeableV2') => {
    await upgradeMarketplaceUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeMarketplaceUpgradeableMain('0x8146a2Acd690961f5862a997DeeeCa9d0DaffD2c');
