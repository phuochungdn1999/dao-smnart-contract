import { ethers } from 'hardhat';
import upgradeGameUpgradeable from './upgradeGame';

const upgradeGameUpgradeableMain = async (baseAddress: string, version: string = 'GameUpgradeable') => {
    await upgradeGameUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeGameUpgradeableMain('0x808071Ec94993fa1222aCe2AcCB95948C072F07F'); // mainnet
upgradeGameUpgradeableMain('0xaB4C0d32D6cc96FE4528bA061A2ed75F23B3ad23'); // testnet

