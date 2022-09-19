import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradeRunnơUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'RUNNOWUpgradeable') => {
    const RunnowUpgradeableFactory = await ethers.getContractFactory(version, deployer);
    const RunnowUpgradeableInstance = await upgrades.upgradeProxy(baseAddress, RunnowUpgradeableFactory);
    console.log('GameUpgradeable upgraded');

    return RunnowUpgradeableInstance;
};

export default upgradeRunnơUpgradeable;
