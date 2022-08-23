import { ethers } from 'hardhat';
import upgradeVestingUpgradeable from './upgradeVesting';

const upgradeVestingUpgradeableMain = async (baseAddress: string, version: string = 'VestingUpgradeable') => {
    await upgradeVestingUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradeVestingUpgradeableMain('0x4721f4ea9250F8E4DfCc024c3bFCEA3204c529D5'); // mainnet
// upgradeVestingUpgradeableMain('0x9eB40DfD758c98740AFa0D7161FC9e3F7FaB7a44'); // testnet

