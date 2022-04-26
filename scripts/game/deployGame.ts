import { ethers, upgrades } from 'hardhat';

const deployGameUpgradeable = async () => {
    const accounts = await ethers.getSigners();
    const upgradeableFactory = await ethers.getContractFactory("GameUpgradeable", accounts[0]);
    const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
    await proxyInstance.deployed();
    console.log("GameUpgradeable: ", proxyInstance.address);
    return proxyInstance;
};
export default deployGameUpgradeable;
