import { ethers } from "hardhat";
import deployVestingUpgradeable from "./deployVesting";

const deployVestingUpgradeableMain = async () => {
  await deployVestingUpgradeable((await ethers.getSigners())[0]);
};

deployVestingUpgradeableMain();
