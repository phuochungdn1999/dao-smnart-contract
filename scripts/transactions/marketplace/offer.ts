import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import { hashOrderItem } from '../../../utils/hashMarketplaceItem';
import { getMarketplaceContract, getNFTContract, getRUNNOWContract } from '../contract';
import { redeem } from '../nft/redeem';


export const offer = async (data: any) => {
    const [deployer, user]: SignerWithAddress[] = await ethers.getSigners();
    const RUNNOWContract = await getRUNNOWContract(data.RUNNOWAddress, deployer);
    const NFTContract = await getNFTContract(data.NFTAddress, deployer);
    const MarketplaceContract = await getMarketplaceContract(data.marketplaceAddress, deployer);

    await RUNNOWContract.connect(user).approve(
        NFTContract.address,
        ethers.utils.parseEther('25')
    );

    // Premint
    const nft = await redeem({
        RUNNOWAddress: data.RUNNOWAddress,
        NFTAddress: data.NFTAddress,
        id: data.id,
        itemType: data.itemType
    });

    await NFTContract.connect(user).setApprovalForAll(
        MarketplaceContract.address,
        true
    );

    // // Offer
    const nonce2 = uuidv4();
    const auth2 = {
        signer: deployer,
        contract: MarketplaceContract.address,
    };
    const types2 = {
        OrderItemStruct: [
            { name: 'id', type: 'string' },
            { name: 'itemType', type: 'string' },
            { name: 'tokenId', type: 'uint256' },
            { name: 'itemAddress', type: 'address' },
            { name: 'price', type: 'uint256' },
            { name: 'priceTokenAddress', type: 'address' },
            { name: 'nonce', type: 'string' },
        ],
    };
    const orderItem2 = {
        id: data.id,
        itemType: data.itemType,
        tokenId: nft?.tokenId,
        itemAddress: NFTContract.address,
        price: data.price,
        priceTokenAddress: RUNNOWContract.address,
        nonce: nonce2,
    };

    const signature2 = await hashOrderItem(types2, auth2, orderItem2);
    const tx2 = await MarketplaceContract.connect(user).offer(signature2);
    const receipt = await tx2.wait();

    const event = receipt.events?.filter((x: any) => {
        return x.event === 'OfferEvent';
    });
    if (event) {
        return {
            id: event[0].args?.id,
        };
    }
    return null;

};

// offer({
//     RUNNOWAddress: "0x7d286935bb8804a4DF43b2EE01E776fA9aB636F2",
//     NFTAddress: "0x40b6a24C58a37804C02A8a48F495eD03c1Df3831",
//     marketplaceAddress: "0x1b0d7036B231016714676bc6bFB1697e7C0fc670",
//     id: "123",
//     itemType: "box",
//     price: ethers.utils.parseEther('100'),

// });
