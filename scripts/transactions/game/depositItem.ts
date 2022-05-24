import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import { createVoucher } from '../../../utils/hashVoucher';
import { getGameContract, getRUNGEMContract } from '../contract';
import { redeem } from '../nft/redeem';

export const depositItem = async (data: any) => {
    const [deployer, user] = await ethers.getSigners();
    const NFTContract = await getRUNGEMContract(data.NFTAddress, deployer);
    const GameContract = await getGameContract(data.GAMEAddress, deployer);

    // Mint a NFT - box
    const nft = await redeem({
        RUNNOWAddress: data.RUNNOWAddress,
        NFTAddress: data.NFTAddress,
        id: data.id,
        itemType: data.itemType
    });

    if (!nft) {
        console.log("===================================");
        console.log("Mint NFT failed");
        console.log("===================================");
        return null;
    }

    // Approve NFT of user to game contract
    let tx = await NFTContract.connect(user).approve(
        GameContract.address,
        nft.tokenId
    );
    await tx.wait();

    // Create depositNFT voucher
    const nonce = uuidv4();
    const auth = {
        signer: deployer,
        contract: GameContract.address,
    };
    const types = {
        DepositItemStruct: [
            { name: 'id', type: 'string' },
            { name: 'itemAddress', type: 'address' },
            { name: 'tokenId', type: 'uint256' },
            { name: 'itemType', type: 'string' },
            { name: 'nonce', type: 'string' },
        ],
    };

    const voucher2 = {
        id: data.id,
        itemAddress: NFTContract.address,
        tokenId: nft.tokenId,
        itemType: data.itemType,
        nonce: nonce,
    };

    const signature2 = await createVoucher(types, auth, voucher2);
    // Send voucher (with signature) to game contract to deposit NFT
    tx = await GameContract.connect(user).depositItem(signature2);
    const receipt = await tx.wait();
    const event = receipt.events?.filter((x: any) => {
        return x.event === 'DepositItemEvent';
    });

    if (event) {
        console.log("===================================");
        console.log("Successfully Deposit item to game ");
        console.log("===================================");
        console.log(`Transaction hash: ${event[0].transactionHash} \n`,);
        return { tokenId: nft.tokenId };
    }
    return null;
};

// depositItem({
//     RUNNOWAddress: "0xF926747D59031C2c2a87149F25c642bD8e490787",
//     NFTAddress: "0x008379787036097FeB45b1e51b0aAaCFD7CAEC03",
//     GAMEAddress: "0x4D76ed2580996f454BCDb084754b74628B43EB40",
//     id: "123",
//     itemType: "box"
// });
