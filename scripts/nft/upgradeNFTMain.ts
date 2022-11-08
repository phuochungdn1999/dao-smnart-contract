import { ethers } from 'hardhat';
import upgradeNFTUpgradeable from './upgradeNFT';

const upgradeNFTUpgradeableMain = async (baseAddress: string, version: string = 'RunnowNFTUpgradeableV2') => {
    await upgradeNFTUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeNFTUpgradeableMain('0xD50209E7b6B01646D5bd987476Ac6A8B0f57da66'); // mainnet
upgradeNFTUpgradeableMain('0xD2940D697Eb9Cd749Fef8B10FC9311FEE280C36E'); // testnet

