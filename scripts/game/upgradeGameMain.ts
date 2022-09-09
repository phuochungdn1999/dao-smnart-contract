import { ethers } from 'hardhat';
import upgradeGameUpgradeable from './upgradeGame';

const upgradeGameUpgradeableMain = async (baseAddress: string, version: string = 'GameUpgradeable') => {
    await upgradeGameUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeGameUpgradeableMain('0x808071Ec94993fa1222aCe2AcCB95948C072F07F'); // mainnet
upgradeGameUpgradeableMain('0x9eB40DfD758c98740AFa0D7161FC9e3F7FaB7a44'); // testnet

