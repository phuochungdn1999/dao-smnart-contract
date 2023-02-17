import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, upgrades } from "hardhat";

const deployDAOUpgradeable = async (deployer: SignerWithAddress) => {
  const upgradeableFactory = await ethers.getContractFactory(
    "CleAthDAOUpgradeable",
    deployer
  );
  const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
  await proxyInstance.deployed();
  console.log("CleAthDAOUpgradeable proxy's address: ", proxyInstance.address);

  return proxyInstance;
};
export default deployDAOUpgradeable;
