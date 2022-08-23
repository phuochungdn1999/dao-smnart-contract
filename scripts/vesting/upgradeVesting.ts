import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradeVestingUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'VestingUpgradeable') => {
    const VestingUpgradeableFactory = await ethers.getContractFactory(version, deployer);
    const VestingUpgradeableInstance = await upgrades.upgradeProxy(baseAddress, VestingUpgradeableFactory);
    console.log('VestingUpgradeable upgraded');

    return VestingUpgradeableInstance;
};

export default upgradeVestingUpgradeable;
