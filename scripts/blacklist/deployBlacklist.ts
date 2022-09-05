import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const deployBlacklistUpgradeable = async (deployer: SignerWithAddress) => {
  const upgradeableFactory = await ethers.getContractFactory('BlacklistUpgradeable', deployer);
  const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
  await proxyInstance.deployed();
  console.log('Blacklist proxy\'s address: ', proxyInstance.address);

  return proxyInstance;
};

export default deployBlacklistUpgradeable;
