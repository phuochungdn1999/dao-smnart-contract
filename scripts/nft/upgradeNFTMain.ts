import { ethers } from 'hardhat';
import upgradeNFTUpgradeable from './upgradeNFT';

const upgradeNFTUpgradeableMain = async (baseAddress: string, version: string = 'NFTUpgradeableV2') => {
    await upgradeNFTUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeNFTUpgradeableMain('0x05730a34aDE0b9d3F71bE29195bEd21c05Dceb9B');
