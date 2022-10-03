import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradeSeedSalesUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'IDOBuyUpgradeable') => {
    const SeedSalesUpgradeableFactory = await ethers.getContractFactory(version, deployer);
    const SeedSalesUpgradeableInstance = await upgrades.upgradeProxy(baseAddress, SeedSalesUpgradeableFactory);
    console.log('SeedSalesUpgradeable upgraded');

    return SeedSalesUpgradeableInstance;
};

export default upgradeSeedSalesUpgradeable;
