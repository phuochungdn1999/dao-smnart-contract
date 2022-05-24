import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import { createVoucher } from '../../../utils/hashVoucher';
import { getNFTContract, getRUNNOWContract } from '../contract';


export const redeem = async (data: any) => {
    const [deployer, user]: SignerWithAddress[] = await ethers.getSigners();
    const RUNNOWContract = await getRUNNOWContract(data.RUNNOWAddress, deployer);
    const NFTContract = await getNFTContract(data.NFTAddress, deployer);

    await RUNNOWContract.connect(user).approve(
        NFTContract.address,
        ethers.utils.parseEther('25')
    );

    const nonce = uuidv4();
    const auth = {
        signer: deployer,
        contract: NFTContract.address,
    };
    const types = {
        ItemVoucherStruct: [
            { name: 'id', type: 'string' },
            { name: 'itemType', type: 'string' },
            { name: 'price', type: 'uint256' },
            { name: 'priceTokenAddress', type: 'address' },
            { name: 'nonce', type: 'string' },
        ],
    };
    const voucher = {
        id: data.id,
        itemType: data.itemType,
        price: ethers.utils.parseEther('25'),
        priceTokenAddress: RUNNOWContract.address,
        nonce: nonce,
    };

    const signature = await createVoucher(types, auth, voucher);
    const tx = await NFTContract.connect(user).redeem(signature);

    const receipt = await tx.wait();
    const event = receipt.events?.filter((x: any) => {
        return x.event === 'RedeemEvent';
    });
    if (event) {
        return {
            tokenId: event[0].args?.tokenId,
        };
    }
    return null;
};

// redeem({
//     RUNNOWAddress: "0x7d286935bb8804a4DF43b2EE01E776fA9aB636F2",
//     NFTAddress: "0x40b6a24C58a37804C02A8a48F495eD03c1Df3831",
//     id: '123',
//     itemType: 'box'
// }).then();
