import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import deployRUNGEMUpgradeable from '../../scripts/coin/deployRUNGEM';
import deployRUNNOWUpgradeable from '../../scripts/coin/deployRUNNOW';
import deployGameUpgradeable from '../../scripts/game/deployGame';
import deployNFTUpgradeable from '../../scripts/nft/deployNFT';
import upgradeNFTUpgradeable from '../../scripts/nft/upgradeNFT';
import { createVoucher } from '../../utils/hashVoucher';

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let client: SignerWithAddress;
let RUNNOWContract: Contract;
let RUNGEMContract: Contract;
let NFTContract: Contract;
let GameContract: Contract;

describe("Game", async () => {
    beforeEach(async () => {
        [deployer, user, client] = await ethers.getSigners();
        RUNNOWContract = await deployRUNNOWUpgradeable(deployer);
        RUNGEMContract = await deployRUNGEMUpgradeable(deployer);
        NFTContract = await deployNFTUpgradeable(deployer);
        GameContract = await deployGameUpgradeable(deployer);
    });

    describe("Withdraw token", () => {
        beforeEach(async () => {
            await RUNNOWContract.connect(deployer).transfer(
                GameContract.address,
                ethers.utils.parseEther("10000")
            );
        });

        it('returns right data', async () => {
            const nonce = uuidv4();
            const auth = {
                signer: deployer,
                contract: GameContract.address,
            };
            const type = {
                WithdrawTokenVoucherStruct: [
                    { name: "tokenAddress", type: "address" },
                    { name: "amount", type: "uint256" },
                    { name: "nonce", type: "string" },
                ],
            };
            const voucher = {
                tokenAddress: RUNNOWContract.address,
                amount: ethers.utils.parseEther("100"),
                nonce: nonce,
            };

            const signature = await createVoucher(type, auth, voucher);
            const balanceOfUserBefore = await RUNNOWContract.connect(user).balanceOf(
                user.address
            );
            expect(balanceOfUserBefore.toString()).to.equal("0");
            const tx = await GameContract.connect(user).withdrawToken(signature);
            await tx.wait();
            const balanceOfUserAfter = await RUNNOWContract.connect(user).balanceOf(
                user.address
            );
            expect(balanceOfUserAfter.toString()).to.equal(
                ethers.utils.parseEther("100").toString()
            );
        });
    });

    describe('Deposit token', () => {
        context('when deposit RUNNOW token', async () => {
            context('when success', async () => {
                beforeEach(async () => {
                    await RUNNOWContract.connect(deployer).transfer(
                        user.address,
                        ethers.utils.parseEther('1000')
                    );
                });

                it('updates right balance of user and balance of game', async () => {
                    const balanceOfUserBefore = await RUNNOWContract.connect(user).balanceOf(user.address);
                    const balanceOfGameBefore = await RUNNOWContract.connect(user).balanceOf(GameContract.address);

                    let tx = await RUNNOWContract.connect(user).approve(
                        GameContract.address,
                        ethers.utils.parseEther('1000')
                    );
                    await tx.wait();

                    tx = await GameContract.connect(user).depositToken(
                        RUNNOWContract.address,
                        ethers.utils.parseEther('300')
                    );
                    await tx.wait();

                    const balanceOfUserAfter = await RUNNOWContract.connect(user).balanceOf(user.address);
                    const balanceOfGameAfter = await RUNNOWContract.connect(user).balanceOf(GameContract.address);

                    expect(balanceOfUserAfter.toString()).to.equal(ethers.utils.parseEther("700"));
                    expect(balanceOfGameAfter.toString()).to.equal(ethers.utils.parseEther("300"));
                });
            });

            context('when error', async () => {
                context('when user balance equal 0', async () => {
                    it('returns transfer amount exceeds balance', async () => {
                        const balanceOfUserBefore = await RUNNOWContract.connect(user).balanceOf(
                            user.address
                        );
                        const balanceOfGameBefore = await RUNNOWContract.connect(user).balanceOf(
                            GameContract.address
                        );

                        let tx = await RUNNOWContract.connect(user).approve(
                            GameContract.address,
                            ethers.utils.parseEther('1000')
                        );
                        await tx.wait();

                        await expect(GameContract.connect(user).depositToken(
                            RUNNOWContract.address,
                            ethers.utils.parseEther('300')
                        )).to.be.revertedWith('ERC20: transfer amount exceeds balance');
                    });
                });

                context('when deposit amount equal 0', async () => {
                    beforeEach(async () => {
                        await RUNNOWContract.connect(deployer).transfer(
                            user.address,
                            ethers.utils.parseEther('1000')
                        );
                    });

                    it('returns amount must greater than zero', async () => {
                        const balanceOfUserBefore = await RUNNOWContract.connect(user).balanceOf(
                            user.address
                        );
                        const balanceOfGameBefore = await RUNNOWContract.connect(user).balanceOf(
                            GameContract.address
                        );

                        let tx = await RUNNOWContract.connect(user).approve(
                            GameContract.address,
                            ethers.utils.parseEther('1000')
                        );
                        await tx.wait();

                        await expect(GameContract.connect(user).depositToken(
                            RUNNOWContract.address,
                            ethers.utils.parseEther('0')
                        )).to.be.revertedWith('Amount must greater than zero');
                    });
                });
            });
        });

        context('when deposite RUNGEM token', async () => {
            context('when success', async () => {
                beforeEach(async () => {
                    await RUNGEMContract.connect(deployer).transfer(
                        user.address,
                        ethers.utils.parseEther('1000')
                    );
                });

                it('updates right balance of user and balance of game', async () => {
                    const balanceOfUserBefore = await RUNGEMContract.connect(user).balanceOf(user.address);
                    const balanceOfGameBefore = await RUNGEMContract.connect(user).balanceOf(GameContract.address);

                    let tx = await RUNGEMContract.connect(user).approve(
                        GameContract.address,
                        ethers.utils.parseEther('1000')
                    );
                    await tx.wait();

                    tx = await GameContract.connect(user).depositToken(
                        RUNGEMContract.address,
                        ethers.utils.parseEther('300')
                    );
                    await tx.wait();

                    const balanceOfUserAfter = await RUNGEMContract.connect(user).balanceOf(user.address);
                    const balanceOfGameAfter = await RUNGEMContract.connect(user).balanceOf(GameContract.address);

                    expect(balanceOfUserAfter.toString()).to.equal(ethers.utils.parseEther("700"));
                    expect(balanceOfGameAfter.toString()).to.equal(ethers.utils.parseEther("300"));
                });
            });

            context('when error', async () => {
                context('when user balance equal 0', async () => {
                    it('returns transfer amount exceeds balance', async () => {
                        const balanceOfUserBefore = await RUNGEMContract.connect(user).balanceOf(
                            user.address
                        );
                        const balanceOfGameBefore = await RUNGEMContract.connect(user).balanceOf(
                            GameContract.address
                        );

                        let tx = await RUNGEMContract.connect(user).approve(
                            GameContract.address,
                            ethers.utils.parseEther('1000')
                        );
                        await tx.wait();

                        await expect(GameContract.connect(user).depositToken(
                            RUNGEMContract.address,
                            ethers.utils.parseEther('300')
                        )).to.be.revertedWith('ERC20: transfer amount exceeds balance');
                    });
                });

                context('when deposit amount equal 0', async () => {
                    beforeEach(async () => {
                        await RUNGEMContract.connect(deployer).transfer(
                            user.address,
                            ethers.utils.parseEther('1000')
                        );
                    });

                    it('returns amount must greater than zero', async () => {
                        const balanceOfUserBefore = await RUNGEMContract.connect(user).balanceOf(
                            user.address
                        );
                        const balanceOfGameBefore = await RUNGEMContract.connect(user).balanceOf(
                            GameContract.address
                        );

                        let tx = await RUNGEMContract.connect(user).approve(
                            GameContract.address,
                            ethers.utils.parseEther('1000')
                        );
                        await tx.wait();

                        await expect(GameContract.connect(user).depositToken(
                            RUNGEMContract.address,
                            ethers.utils.parseEther('0')
                        )).to.be.revertedWith('Amount must greater than zero');
                    });
                });
            });
        });
    });

    it("Deposit item", async () => {
        // Upgrade
        const NFTContractV2 = await upgradeNFTUpgradeable(NFTContract.address, deployer);


        await RUNNOWContract.connect(deployer).transfer(
            user.address,
            ethers.utils.parseEther('10000')
        );

        // Mint box
        await RUNNOWContract.connect(user).approve(
            NFTContractV2.address,
            ethers.utils.parseEther('25')
        );
        const nonce1 = uuidv4();
        const auth1 = {
            signer: deployer,
            contract: NFTContractV2.address,
        };
        const types1 = {
            ItemVoucherStruct: [
                { name: 'id', type: 'string' },
                { name: 'itemType', type: 'string' },
                { name: 'price', type: 'uint256' },
                { name: 'priceTokenAddress', type: 'address' },
                { name: 'nonce', type: 'string' },
            ],
        };
        const voucher1 = {
            id: '123',
            itemType: 'box',
            price: ethers.utils.parseEther('25'),
            priceTokenAddress: RUNNOWContract.address,
            nonce: nonce1,
        };
        const signature1 = await createVoucher(types1, auth1, voucher1);
        const tx1 = await NFTContractV2.connect(user).redeem(signature1);
        await tx1.wait();

        // Approve NFT of user to game contract
        const tx3 = await NFTContractV2.connect(user).approve(
            GameContract.address,
            1
        );
        await tx3.wait();

        // User deposit NFT to game smart contract
        await GameContract.connect(user).depositItem('123', NFTContractV2.address, 1, 'box');

        const ownerTokenBefore = await NFTContractV2.ownerOf(1);
        expect(ownerTokenBefore).to.equal(GameContract.address);
    });

    it('Withdraw item', async () => {
        // Upgrade NFT Contract
        const NFTContractV2 = await upgradeNFTUpgradeable(NFTContract.address, deployer);

        await RUNNOWContract.connect(deployer).transfer(
            user.address,
            ethers.utils.parseEther('10000')
        );

        // Mint box
        await RUNNOWContract.connect(user).approve(
            NFTContractV2.address,
            ethers.utils.parseEther('25')
        );
        const nonce1 = uuidv4();
        const auth1 = {
            signer: deployer,
            contract: NFTContractV2.address,
        };
        const types1 = {
            ItemVoucherStruct: [
                { name: 'id', type: 'string' },
                { name: 'itemType', type: 'string' },
                { name: 'price', type: 'uint256' },
                { name: 'priceTokenAddress', type: 'address' },
                { name: 'nonce', type: 'string' },
            ],
        };
        const voucher1 = {
            id: '123',
            itemType: 'box',
            price: ethers.utils.parseEther('25'),
            priceTokenAddress: RUNNOWContract.address,
            nonce: nonce1,
        };
        const signature1 = await createVoucher(types1, auth1, voucher1);
        const tx1 = await NFTContractV2.connect(user).redeem(signature1);
        await tx1.wait();

        const ownerTokenBefore = await NFTContractV2.ownerOf(1);
        expect(ownerTokenBefore).to.equal(user.address);

        // Approve NFT of user to game contract
        const tx3 = await NFTContractV2.connect(user).approve(
            GameContract.address,
            1
        );
        await tx3.wait();

        // User deposit NFT to game smart contract
        await GameContract.connect(user).depositItem('123', NFTContractV2.address, 1, 'box');

        // Create withdrawNFT voucher
        const nonce2 = uuidv4();
        const auth2 = {
            signer: deployer,
            contract: GameContract.address,
        };
        const types2 = {
            WithdrawItemVoucherStruct: [
                { name: 'id', type: 'string' },
                { name: 'tokenAddress', type: 'address' },
                { name: 'tokenId', type: 'uint256' },
                { name: 'itemType', type: 'string' },
                { name: 'nonce', type: 'string' },
            ],
        };

        const voucher2 = {
            id: '123',
            tokenAddress: NFTContractV2.address,
            tokenId: 1,
            itemType: 'box',
            nonce: nonce2,
        };

        const signature2 = await createVoucher(types2, auth2, voucher2);

        // Send voucher (with signature) to game contract to withdraw NFT
        const tx2 = await GameContract.connect(user).withdrawItem(signature2);
        const receipt = await tx2.wait();
        const event = receipt.events?.filter((x: any) => {
            return x.event === 'WithdrawNFT';
        });
        console.log('Event: ', event);

        const ownerToken = await NFTContractV2.ownerOf(1);
        expect(ownerToken).to.equal(user.address);
    });

    // it("Craft item", async () => {
    //     // Upgrade
    //     const GameContract = await upgradeGameUpgradeable(GameContract.address, deployer);
    //     const NFTContractV2 = await upgradeNFTUpgradeable(NFTContract.address, deployer);

    //     const nonce1 = uuidv4();
    //     const auth1 = {
    //         signer: deployer,
    //         contract: GameContract.address,
    //     };
    //     const types1 = {
    //         WithdrawItemVoucherStruct: [
    //             { name: 'id', type: 'string' },
    //             { name: "tokenAddress", type: "address" },
    //             { name: "tokenId", type: "uint256" },
    //             { name: "nonce", type: "string" },
    //             // { name: "itemType", type: "string" },
    //         ],
    //     };
    //     const voucher1 = {
    //         id: '123',
    //         tokenAddress: NFTContractV2.address,
    //         tokenId: 0,
    //         nonce: nonce1,
    //         // itemType: 'Box'
    //     };
    //     const signature1 = await createVoucher(types1, auth1, voucher1);

    //     // send voucher (with signature) to game contract to withdraw NFT
    //     const tx3 = await GameContract.connect(user).withdrawItem(signature1);
    //     const receipt = await tx3.wait();
    //     const event = receipt.events?.filter((x: any) => {
    //         return x.event === "WithdrawNFT";
    //     });
    //     console.log("event: ", event);

    //     const ownerToken = await NFTContractV2.ownerOf(1);
    //     expect(ownerToken).to.equal(user.address);
    // });
});
