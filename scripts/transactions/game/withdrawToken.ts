import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import { createVoucher } from '../../../utils/hashVoucher';
import { getGameContract, getRUNGEMContract } from '../contract';
import { depositToken } from './depositToken';

export const withdrawToken = async (data: any): Promise<boolean> => {
    const [deployer, user]: SignerWithAddress[] = await ethers.getSigners();
    const RUNNOWContract = await getRUNGEMContract(data.RUNNOWAddress, deployer);
    const GameContract = await getGameContract(data.GAMEAddress, deployer);

    // Deposit 100 RUNNOW to Game contract
    const success = await depositToken({
        RUNNOWAddress: data.RUNNOWAddress,
        GAMEAddress: data.GAMEAddress,
        amount: ethers.utils.parseEther("100")
    });
    if (!success) {
        console.log("=======================");
        console.log("Deposit token failed");
        console.log("=======================");
        return false;
    }

    // User withdraw 100 token from user.
    // Sign message
    const nonce = uuidv4();
    const auth = {
        signer: deployer,
        contract: GameContract.address,
    };
    const type = {
        WithdrawTokenStruct: [
            { name: 'tokenAddress', type: 'address' },
            { name: 'amount', type: 'uint256' },
            { name: 'nonce', type: 'string' },
        ],
    };
    const voucher = {
        tokenAddress: RUNNOWContract.address,
        amount: data.amount,
        nonce: nonce,
    };
    const signature = await createVoucher(type, auth, voucher);

    // Call withdraw transaction
    const tx = await GameContract.connect(user).withdrawToken(signature);
    const receipt = await tx.wait();

    // Listening event
    const event = receipt.events?.filter((x: any) => {
        return x.event === 'WithdrawTokenEvent';
    });
    if (event) {
        console.log("===================================");
        console.log("Successfully Withdraw token from game ");
        console.log("===================================");
        console.log(`Transaction hash: ${event[0].transactionHash} \n`,);
        return true;
    }
    return false;
};

// withdrawToken({
//     RUNNOWAddress: "0xdE5efE5D20C61391b19466dbCdEc7BA53d76AC11",
//     GAMEAddress: "0x93F6b397d0206422AE786DF9E964c43F0495df9e",
//     amount: ethers.utils.parseEther("50")
// }).then();
