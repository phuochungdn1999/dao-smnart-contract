import { ethers } from "hardhat";
import deployDAOUpgradeable from "./deployDAO";

const deployDAOUpgradeableMain = async () => {
  await deployDAOUpgradeable((await ethers.getSigners())[0]);
};

deployDAOUpgradeableMain();
