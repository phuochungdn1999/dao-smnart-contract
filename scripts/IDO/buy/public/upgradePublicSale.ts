import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradePublicSalesUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'IDOBuyUpgradeable') => {
    const PublicSalesUpgradeableFactory = await ethers.getContractFactory(version, deployer);
    const PublicSalesUpgradeableInstance = await upgrades.upgradeProxy(baseAddress, PublicSalesUpgradeableFactory);
    console.log('PublicSalesUpgradeable upgraded');

    return PublicSalesUpgradeableInstance;
};

export default upgradePublicSalesUpgradeable;
