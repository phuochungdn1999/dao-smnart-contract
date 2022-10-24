import { ethers } from 'hardhat';
import deployVaultUpgradeable from './deployVault';

const deployVaultUpgradeableMain = async () => {
    await deployVaultUpgradeable((await ethers.getSigners())[0]);
};

deployVaultUpgradeableMain();
