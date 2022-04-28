import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers, upgrades } from 'hardhat';

const upgradeGameUpgradeable = async (baseAddress: string, deployer: SignerWithAddress, version: string = 'GameUpgradeableV2') => {
    const GameUpgradeableV2Factory = await ethers.getContractFactory(version, deployer);
    const GameUpgradeableV2Instance = await upgrades.upgradeProxy(baseAddress, GameUpgradeableV2Factory);
    console.log('GameUpgradeable upgraded');

    return GameUpgradeableV2Instance;
};

export default upgradeGameUpgradeable;
