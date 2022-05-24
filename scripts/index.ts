import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import deployRUNGEMUpgradeable from './coin/deployRUNGEM';
import deployRUNNOWUpgradeable from './coin/deployRUNNOW';
import deployGameUpgradeable from './game/deployGame';
import deployMarketplaceUpgradeable from './marketplace/deployMarketplace';
import deployNFTUpgradeable from './nft/deployNFT';

const deployAll = async () => {
    const [deployer, user]: SignerWithAddress[] = await ethers.getSigners();

    // Deploy RUNNOW
    const RUNNOWInstance = await deployRUNNOWUpgradeable(deployer);

    // Deploy RUNGEM
    const RUNGEMInstance = await deployRUNGEMUpgradeable(deployer);

    //Transfer token for the user
    await RUNNOWInstance.connect(deployer).transfer(user.address, ethers.utils.parseEther("1000"));
    await RUNGEMInstance.connect(deployer).transfer(user.address, ethers.utils.parseEther("1000"));

    // Deploy NFT
    await deployNFTUpgradeable(deployer);

    //Deploy marketplace
    await deployMarketplaceUpgradeable(deployer);

    //Deploy game
    await deployGameUpgradeable(deployer);
};

deployAll().then();
