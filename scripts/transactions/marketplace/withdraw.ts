import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { getMarketplaceContract } from '../contract';
import { offer } from './offer';

export const withdraw = async (data: any) => {
    const [deployer, user]: SignerWithAddress[] = await ethers.getSigners();
    const MarketplaceContract = await getMarketplaceContract(data.marketplaceAddress, deployer);
    // Create offer NFT
    const offerData = await offer({
        RUNNOWAddress: data.RUNNOWAddress,
        NFTAddress: data.NFTAddress,
        marketplaceAddress: data.marketplaceAddress,
        id: data.id,
        itemType: data.itemType,
        price: data.price,
    });
    if (!offerData) {
        console.log("Task is failed");
        return;
    }
    const tx3 = await MarketplaceContract.connect(user).withdraw(offerData.id);
    const receipt = await tx3.wait();

    const event = receipt.events?.filter((x: any) => {
        return x.event === 'WithdrawEvent';
    });
};

// withdraw({
//     RUNNOWAddress: "0x7d286935bb8804a4DF43b2EE01E776fA9aB636F2",
//     NFTAddress: "0x40b6a24C58a37804C02A8a48F495eD03c1Df3831",
//     marketplaceAddress: "0x1b0d7036B231016714676bc6bFB1697e7C0fc670",
//     id: "1111", // Change when each call
//     itemType: "box",
//     price: ethers.utils.parseEther('100')
// });
