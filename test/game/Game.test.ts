import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from "uuid";
import deployRUNNOW from '../../scripts/coin/deployRUNNOW';
import deployGame from '../../scripts/game/deployGameUpgradeable';
import { createVoucher } from '../../utils/hashVoucher';

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let client: SignerWithAddress;
let RUNNOWContract: Contract;
describe("Game", async () => {
    beforeEach(async () => {
        [deployer, user, client] = await ethers.getSigners();
        RUNNOWContract = await deployRUNNOW();
        await RUNNOWContract.connect(deployer).transfer(user.address, ethers.utils.parseEther("1000"));
        await RUNNOWContract.connect(deployer).transfer(client.address, ethers.utils.parseEther("1000"));
    });

    it("Deploy Game proxy", async () => {
        // deploy game proxy contract
        const GameContract = await deployGame();

        // Check deposit token function
        // Approve 10 ether of the user for game proxy contract
        let tx = await RUNNOWContract.connect(user).approve(GameContract.address, ethers.utils.parseEther("10"));
        await tx.wait();

        // User deposit 10 ether to game proxy contract
        tx = await GameContract.connect(user).depositToken(RUNNOWContract.address, ethers.utils.parseEther("10"));
        await tx.wait();

        // Check ZODIBO balance of the user
        const userBalance = await RUNNOWContract.connect(user).balanceOf(user.address);
        expect(userBalance.toString()).to.equal(ethers.utils.parseEther("990"));

        //Check ZODIBO balance of the game
        const gameBalance = await RUNNOWContract.connect(user).balanceOf(GameContract.address);
        expect(gameBalance.toString()).to.equal(ethers.utils.parseEther("10"));

        // Check withdraw Token function
        // Create signature
        const nonce = uuidv4();

        const auth = {
            signer: deployer,
            contract: GameContract.address,
        };
        const type = {
            WithdrawTokenVoucher: [
                { name: "withdrawer", type: "address" },
                { name: "tokenAddress", type: "address" },
                { name: "amount", type: "uint256" },
                { name: "nonce", type: "string" },
            ],
        };
        const voucher = {
            withdrawer: user.address,
            tokenAddress: RUNNOWContract.address,
            amount: ethers.utils.parseEther("10"),
            nonce: nonce,
        };

        const signature = await createVoucher(type, auth, voucher);
        tx = await GameContract.withdrawToken(signature);
        await tx.wait();

        // Check ZODIBO balance of the user after withdraw
        const userBalanceAfter = await RUNNOWContract.connect(user).balanceOf(user.address);
        expect(userBalanceAfter.toString()).to.equal(ethers.utils.parseEther("1000"));

        //Check ZODIBO balance of the game after withdraw
        const gameBalanceAfter = await RUNNOWContract.connect(user).balanceOf(GameContract.address);
        expect(gameBalanceAfter.toString()).to.equal(ethers.utils.parseEther("0"));
    });
});
