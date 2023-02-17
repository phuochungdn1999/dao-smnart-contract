import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, upgrades } from "hardhat";

const upgradeDAOUpgradeable = async (
  baseAddress: string,
  deployer: SignerWithAddress,
  version: string = "CleAthDAOUpgradeable"
) => {
  const RunnowUpgradeableFactory = await ethers.getContractFactory(
    version,
    deployer
  );
  const RunnowUpgradeableInstance = await upgrades.upgradeProxy(
    baseAddress,
    RunnowUpgradeableFactory
  );
  console.log("CleAthDAOUpgradeable upgraded");

  return RunnowUpgradeableInstance;
};

export default upgradeDAOUpgradeable;
