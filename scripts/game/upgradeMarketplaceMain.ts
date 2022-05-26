import { ethers } from 'hardhat';
import upgradeGameUpgradeable from './upgradeGame';

const upgradeGameUpgradeableMain = async (baseAddress: string, version: string = 'GameUpgradeableV2') => {
    await upgradeGameUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeGameUpgradeableMain('0x8146a2Acd690961f5862a997DeeeCa9d0DaffD2c');
