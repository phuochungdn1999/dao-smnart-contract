import { ethers } from "hardhat";
import upgradeRunnowUpgradeable from "./upgradeDAO";

const upgradeDAOUpgradeableMain = async (
  baseAddress: string,
  version: string = "CleAthDAOUpgradeable"
) => {
  await upgradeRunnowUpgradeable(
    baseAddress,
    (
      await ethers.getSigners()
    )[0],
    version
  );
};

upgradeDAOUpgradeableMain("0x227ba0b472f19E0be2fC526BdD9eB828909F973D");
