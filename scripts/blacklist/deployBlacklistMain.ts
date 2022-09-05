import { ethers } from 'hardhat';
import deployBlacklistUpgradeable from './deployBlacklist';

const deployBlacklistUpgradeableMain = async () => {
  await deployBlacklistUpgradeable((await ethers.getSigners())[0]);
};

deployBlacklistUpgradeableMain();

