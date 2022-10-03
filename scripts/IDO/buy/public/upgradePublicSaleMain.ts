import { ethers } from 'hardhat';
import upgradePublicSalesUpgradeable from './upgradePublicSale';

const upgradePublicSalesUpgradeableMain = async (baseAddress: string, version: string = 'IDOBuyUpgradeable') => {
    await upgradePublicSalesUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradePublicSalesUpgradeableMain('0x808071Ec94993fa1222aCe2AcCB95948C072F07F'); // mainnet
// upgradePublicSalesUpgradeableMain('0x9eB40DfD758c98740AFa0D7161FC9e3F7FaB7a44'); // testnet

