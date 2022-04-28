import { ethers } from 'hardhat';
import upgradeGameUpgradeable from './upgradeGame';

const upgradeGameUpgradeableMain = async (baseAddress: string, version: string = 'GameUpgradeableV2') => {
    await upgradeGameUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeGameUpgradeableMain('0x05730a34aDE0b9d3F71bE29195bEd21c05Dceb9B');
