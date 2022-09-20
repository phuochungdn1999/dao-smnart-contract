import { ethers } from 'hardhat';
import deployPrivateSalesUpgradeable from './deployPrivateSale';

const deployPrivateSalesUpgradeableMain = async () => {
    await deployPrivateSalesUpgradeable((await ethers.getSigners())[0]);
};

deployPrivateSalesUpgradeableMain();
