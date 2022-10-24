import { ethers } from 'hardhat';
import upgradeNFTUpgradeable from './upgradeVault';

const upgradeVaultUpgradeableMain = async (baseAddress: string, version: string = 'VaultUpgradeable') => {
    await upgradeNFTUpgradeable(baseAddress, (await ethers.getSigners())[0], version);
};

// upgradeVaultUpgradeableMain('0xD50209E7b6B01646D5bd987476Ac6A8B0f57da66'); // mainnet
upgradeVaultUpgradeableMain('0x4611D6A848f5465310C72E85bAdc580ae6Aa5691'); // testnet

