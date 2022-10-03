import { ethers } from "hardhat";
import deploySeedSalesUpgradeable from "./deploySeedSale";

const deploySeedSalesUpgradeableMain = async () => {
  await deploySeedSalesUpgradeable((await ethers.getSigners())[0]);
};

deploySeedSalesUpgradeableMain();
