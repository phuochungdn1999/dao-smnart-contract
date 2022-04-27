import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradeNFTUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'NFTUpgradeableV2') => {
    const NFTUpgradeableV2Factory = await ethers.getContractFactory(version, deployer);
    const NFTUpgradeableV2Instance = await upgrades.upgradeProxy(baseAddress, NFTUpgradeableV2Factory);
    console.log('NFTUpgradeable upgraded');

    return NFTUpgradeableV2Instance;
};

export default upgradeNFTUpgradeable;
