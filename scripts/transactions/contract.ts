import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';

export const getRUNNOWContract = async (address: string, deployer: SignerWithAddress) => {
    const RUNNOWFactory = await ethers.getContractFactory("RUNNOWUpgradeable", deployer);
    const RUNNUWInstance = RUNNOWFactory.attach(address);
    return RUNNUWInstance;
};

export const getRUNGEMContract = async (address: string, deployer: SignerWithAddress) => {
    const RUNGEMFactory = await ethers.getContractFactory("RUNGEMUpgradeable", deployer);
    const RUNGEMInstance = RUNGEMFactory.attach(address);
    return RUNGEMInstance;
};

export const getMarketplaceContract = async (address: string, deployer: SignerWithAddress) => {
    const marketplaceFactory = await ethers.getContractFactory("MarketplaceUpgradeable", deployer);
    const marketplaceInstance = marketplaceFactory.attach(address);
    return marketplaceInstance;
};

export const getGameContract = async (address: string, deployer: SignerWithAddress) => {
    const gameFactory = await ethers.getContractFactory("GameUpgradeable", deployer);
    const gameInstance = gameFactory.attach(address);
    return gameInstance;
};

export const getNFTContract = async (address: string, deployer: SignerWithAddress) => {
    const NFTFactory = await ethers.getContractFactory("NFTUpgradeable", deployer);
    const NFTInstance = NFTFactory.attach(address);
    return NFTInstance;
};
