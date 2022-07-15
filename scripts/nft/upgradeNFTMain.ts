import { ethers } from 'hardhat';
import upgradeNFTUpgradeable from './upgradeNFT';

const upgradeNFTUpgradeableMain = async (baseAddress: string, version: string = 'RunnowNFTUpgradeableV2') => {
    await upgradeNFTUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeNFTUpgradeableMain('0xD50209E7b6B01646D5bd987476Ac6A8B0f57da66'); // mainnet
upgradeNFTUpgradeableMain('0x3437DEFC85627749c4E07F7b372A3dE811b41f9f'); // testnet

