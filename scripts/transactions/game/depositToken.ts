import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { getGameContract, getRUNGEMContract } from '../contract';

export const depositToken = async (data: any): Promise<boolean> => {
    const [deployer, user]: SignerWithAddress[] = await ethers.getSigners();
    const RUNNOWContract = await getRUNGEMContract(data.RUNNOWAddress, deployer);
    const GameContract = await getGameContract(data.GAMEAddress, deployer);

    let tx = await RUNNOWContract.connect(user).approve(
        GameContract.address,
        data.amount
    );
    await tx.wait();

    tx = await GameContract.connect(user).depositToken(
        RUNNOWContract.address,
        data.amount
    );

    const receipt = await tx.wait();
    const event = receipt.events?.filter((x: any) => {
        return x.event === 'DepositTokenEvent';
    });

    if (event) {
        console.log("===================================");
        console.log("Successfully Deposit token to game ");
        console.log("===================================");
        console.log(`Transaction hash: ${event[0].transactionHash} \n`,);
        return true;
    }
    return false;
};

// depositToken({
//     RUNNOWAddress: "0xdE5efE5D20C61391b19466dbCdEc7BA53d76AC11",
//     GAMEAddress: "0x93F6b397d0206422AE786DF9E964c43F0495df9e",
//     amount: ethers.utils.parseEther("30")
// }).then();
