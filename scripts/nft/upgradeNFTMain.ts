import { ethers } from 'hardhat';
import upgradeNFTUpgradeable from './upgradeNFT';

const upgradeNFTUpgradeableMain = async (baseAddress: string, version: string = 'NFTUpgradeableV2') => {
    await upgradeNFTUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradeNFTUpgradeableMain('0x09df26735213E31706E0599A5D9A8D0D1029e0CE');
