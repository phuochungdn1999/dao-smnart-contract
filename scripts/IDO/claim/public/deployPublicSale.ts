import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const deployPublicSalesUpgradeable = async (deployer: SignerWithAddress) => {
    const upgradeableFactory = await ethers.getContractFactory('IDOClaimUpgradeable', deployer);
    const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
    await proxyInstance.deployed();
    console.log('PublicSales proxy\'s address: ', proxyInstance.address);

    return proxyInstance;
};
export default deployPublicSalesUpgradeable;
