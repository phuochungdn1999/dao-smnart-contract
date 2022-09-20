import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const deployPrivateSalesUpgradeable = async (deployer: SignerWithAddress) => {
    const upgradeableFactory = await ethers.getContractFactory('PrivateSalesUpgradeableUpgradeable', deployer);
    const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
    await proxyInstance.deployed();
    console.log('PrivateSales proxy\'s address: ', proxyInstance.address);

    return proxyInstance;
};
export default deployPrivateSalesUpgradeable;
