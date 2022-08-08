import { ethers } from 'hardhat';
import upgradeMarketplaceUpgradeable from './upgradeMarketplace';

const upgradeMarketplaceUpgradeableMain = async (baseAddress: string, version: string = 'MarketplaceV3Upgradeable') => {
    await upgradeMarketplaceUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeMarketplaceUpgradeableMain('0xaB4C0d32D6cc96FE4528bA061A2ed75F23B3ad23'); //testnet
upgradeMarketplaceUpgradeableMain('0x0D51b031cc4CD92560d1F4a94435CF64F7e1d57b'); //mainnet
