import { ethers } from 'hardhat';
import upgradePrivateSalesUpgradeable from './upgradePrivateSale';

const upgradePrivateSalesUpgradeableMain = async (baseAddress: string, version: string = 'PrivateSalesUpgradeable') => {
    await upgradePrivateSalesUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradePrivateSalesUpgradeableMain('0x808071Ec94993fa1222aCe2AcCB95948C072F07F'); // mainnet
// upgradePrivateSalesUpgradeableMain('0x9eB40DfD758c98740AFa0D7161FC9e3F7FaB7a44'); // testnet

