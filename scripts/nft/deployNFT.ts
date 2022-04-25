import { ethers, upgrades } from 'hardhat';

const deployNFTUpgradeable = async () => {
    const accounts = await ethers.getSigners();
    const upgradeableFactory = await ethers.getContractFactory("NFTUpgradeable", accounts[0]);
    const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
    await proxyInstance.deployed();
    console.log("NFTUpgradeable: ", proxyInstance.address);
    return proxyInstance;
};

export default deployNFTUpgradeable;
