import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradeVaultUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'VaultUpgradeable') => {
    const vaultUpgradeableFactory = await ethers.getContractFactory(version, deployer);
    const vaultUpgradeableInstance = await upgrades.upgradeProxy(baseAddress, vaultUpgradeableFactory);
    console.log('VaultUpgradeable upgraded');

    return vaultUpgradeableInstance;
};

export default upgradeVaultUpgradeable;
