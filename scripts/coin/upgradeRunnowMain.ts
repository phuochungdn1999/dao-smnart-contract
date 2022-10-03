import { ethers } from 'hardhat';
import upgradeRunnowUpgradeable from './upgradeRunnow';

const upgradeRunnowUpgradeableMain = async (baseAddress: string, version: string = 'RUNNOWUpgradeable') => {
    await upgradeRunnowUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

upgradeRunnowUpgradeableMain('0xca34779Ef2c950e4c76a65774C46BA5337B5736F'); // mainnet
// upgradeRunnowUpgradeableMain('0x9eB40DfD758c98740AFa0D7161FC9e3F7FaB7a44'); // testnet

