import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradePrivateSalesUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'IDOBuyUpgradeable') => {
    const PrivateSalesUpgradeableFactory = await ethers.getContractFactory(version, deployer);
    const PrivateSalesUpgradeableInstance = await upgrades.upgradeProxy(baseAddress, PrivateSalesUpgradeableFactory);
    console.log('PrivateSalesUpgradeable upgraded');

    return PrivateSalesUpgradeableInstance;
};

export default upgradePrivateSalesUpgradeable;
