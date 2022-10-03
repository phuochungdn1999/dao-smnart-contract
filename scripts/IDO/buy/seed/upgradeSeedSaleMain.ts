import { ethers } from 'hardhat';
import upgradeSeedSalesUpgradeable from './upgradeSeedSale';

const upgradeSeedSalesUpgradeableMain = async (baseAddress: string, version: string = 'IDOBuyUpgradeable') => {
    await upgradeSeedSalesUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradeSeedSalesUpgradeableMain('0x808071Ec94993fa1222aCe2AcCB95948C072F07F'); // mainnet
// upgradeSeedSalesUpgradeableMain('0x9eB40DfD758c98740AFa0D7161FC9e3F7FaB7a44'); // testnet

