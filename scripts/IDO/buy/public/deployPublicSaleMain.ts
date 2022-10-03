import { ethers } from 'hardhat';
import deployPublicSalesUpgradeable from './deployPublicSale';

const deployPublicSalesUpgradeableMain = async () => {
    await deployPublicSalesUpgradeable((await ethers.getSigners())[0]);
};

deployPublicSalesUpgradeableMain();
