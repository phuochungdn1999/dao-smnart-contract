import { ethers } from 'hardhat';
import upgradeNFTUpgradeable from './upgradeNFT';

const upgradeNFTUpgradeableMain = async (baseAddress: string, version: string = 'RunnowNFTUpgradeableV2') => {
    await upgradeNFTUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeNFTUpgradeableMain('0xD50209E7b6B01646D5bd987476Ac6A8B0f57da66'); // mainnet
upgradeNFTUpgradeableMain('0xf8876dBac378b3FB5305CbE78C5Ce954E57CE7f3'); // testnet

