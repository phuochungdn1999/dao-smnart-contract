import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const deploySeedSalesUpgradeable = async (deployer: SignerWithAddress) => {
    const upgradeableFactory = await ethers.getContractFactory('IDOClaimUpgradeable', deployer);
    const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
    await proxyInstance.deployed();
    console.log('SeedSales proxy\'s address: ', proxyInstance.address);

    return proxyInstance;
};
export default deploySeedSalesUpgradeable;
