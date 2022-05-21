import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
import { getMarketplaceContract, getRUNNOWContract } from '../contract';
import { offer } from './offer';

const buy = async (data: any) => {
    const [deployer, user, buyer, feesCollector]: SignerWithAddress[] = await ethers.getSigners();
    const RUNNOWContract = await getRUNNOWContract(data.RUNNOWAddress, deployer);
    const MarketplaceContract = await getMarketplaceContract(data.marketplaceAddress, deployer);

    // Transfer 100 ether to buyer
    await RUNNOWContract.connect(deployer).transfer(buyer.address, ethers.utils.parseEther("100"));

    // Set fee collection
    const feesCollectorCutPerMillion = BigNumber.from(Math.ceil(5 / 100 * 1_000_000));
    let tx = await MarketplaceContract.connect(deployer).setFeesCollectorAddress(
        feesCollector.address
    );
    await tx.wait();
    tx = await MarketplaceContract.connect(deployer).setFeesCollectorCutPerMillion(
        feesCollectorCutPerMillion
    );
    await tx.wait();

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

    tx = await RUNNOWContract.connect(buyer).approve(
        MarketplaceContract.address,
        ethers.utils.parseEther('100')
    );
    await tx.wait();

    // // Buy NFT
    const tx3 = await MarketplaceContract.connect(buyer).buy(offerData.id);
    const receipt = await tx3.wait();
    const event = receipt.events?.filter((x: any) => {
        return x.event === 'BuyEvent';
    });
};

// buy({
//     RUNNOWAddress: "0x7d286935bb8804a4DF43b2EE01E776fA9aB636F2",
//     NFTAddress: "0x40b6a24C58a37804C02A8a48F495eD03c1Df3831",
//     marketplaceAddress: "0x1b0d7036B231016714676bc6bFB1697e7C0fc670",
//     id: "1234", // Change when each call
//     itemType: "box",
//     price: ethers.utils.parseEther('100')
// });
