import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, upgrades } from "hardhat";

const deployRUNNOWUpgradeable = async () => {
  const accounts: SignerWithAddress[] = await ethers.getSigners();
  const upgradeableFactory = await ethers.getContractFactory(
    "RUNNOWUpgradeable",
    accounts[0]
  );
  const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
  await proxyInstance.deployed();

  console.log("RUNNOW proxy's address: ", proxyInstance.address);
  return proxyInstance;
};

export default deployRUNNOWUpgradeable;
