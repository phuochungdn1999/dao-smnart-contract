import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, upgrades } from "hardhat";

const deployVestingUpgradeable = async (deployer: SignerWithAddress) => {
  const upgradeableFactory = await ethers.getContractFactory(
    "VestingUpgradeable",
    deployer
  );
  const proxyInstance = await upgrades.deployProxy(upgradeableFactory);
  await proxyInstance.deployed();
  console.log("Vesting proxy's address: ", proxyInstance.address);

  return proxyInstance;
};

export default deployVestingUpgradeable;
