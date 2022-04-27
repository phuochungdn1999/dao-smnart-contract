import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { assert, expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import deployRUNNOWUpgradeable from '../../scripts/coin/deployRUNNOW';
import deployMarketplaceUpgradeable from '../../scripts/marketplace/deployMarketplace';
import deployNFTUpgradeable from '../../scripts/nft/deployNFT';
import { hashOrderItem } from '../../utils/hashMarketplaceItem';
import { createVoucher } from '../../utils/hashVoucher';

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let buyer: SignerWithAddress;
let dev: SignerWithAddress;
let feesCollector: SignerWithAddress;
let RUNNOWContract: Contract;
let NFTContract: Contract;
let MarketplaceContract: Contract;

describe('Marketplace', async () => {
    beforeEach(async () => {
        [deployer, user, buyer, dev, feesCollector] = await ethers.getSigners();
        RUNNOWContract = await deployRUNNOWUpgradeable();
        NFTContract = await deployNFTUpgradeable(deployer);
        MarketplaceContract = await deployMarketplaceUpgradeable();
        await RUNNOWContract.connect(deployer).transfer(user.address, ethers.utils.parseEther('1000'));
        await RUNNOWContract.connect(deployer).transfer(buyer.address, ethers.utils.parseEther('1000'));
    });

    describe('Offer', () => {
        it('returns right data', async () => {
            await RUNNOWContract.connect(user).approve(
                NFTContract.address,
                ethers.utils.parseEther('25')
            );
            const nonce1 = uuidv4();
            const auth1 = {
                signer: deployer,
                contract: NFTContract.address,
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
            const tx = await NFTContract.connect(user).redeem(signature1);
            await tx.wait();

            await NFTContract.connect(user).setApprovalForAll(
                MarketplaceContract.address,
                true
            );

            const nonce2 = uuidv4();
            const auth2 = {
                signer: deployer,
                contract: MarketplaceContract.address,
            };
            const types2 = {
                OrderItem: [
                    { name: 'seller', type: 'address' },
                    { name: 'itemId', type: 'string' },
                    { name: 'tokenId', type: 'uint256' },
                    { name: 'itemPrice', type: 'uint256' },
                    { name: 'itemAddress', type: 'address' },
                    { name: 'nonce', type: 'string' },
                ],
            };
            const orderItem2 = {
                seller: user.address,
                itemId: '99',
                tokenId: BigNumber.from(1),
                itemPrice: ethers.utils.parseEther('100'),
                itemAddress: NFTContract.address,
                nonce: nonce2,
            };

            const signature2 = await hashOrderItem(types2, auth2, orderItem2);
            const tx2 = await MarketplaceContract.connect(user).offer(signature2);
            const receipt = await tx2.wait();

            const event = receipt.events?.filter((x: any) => {
                return x.event === 'Offer';
            });

            expect(event[0].args.seller).to.equal(user.address);
            expect(event[0].args.itemId).to.equal(orderItem2.itemId);
            expect(event[0].args.itemAddress).to.equal(NFTContract.address);
        });
    });

    describe('Buy', () => {
        it('returns right data - Token ERC-20', async () => {
            await RUNNOWContract.connect(user).approve(
                NFTContract.address,
                ethers.utils.parseEther('100')
            );

            // Mint Box
            const nonce1 = uuidv4();
            const auth1 = {
                signer: deployer,
                contract: NFTContract.address,
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
            const tx = await NFTContract.connect(user).redeem(signature1);
            await tx.wait();

            await NFTContract.connect(user).setApprovalForAll(
                MarketplaceContract.address,
                true
            );

            // Offer box
            const nonce2 = uuidv4();
            const auth2 = {
                signer: deployer,
                contract: MarketplaceContract.address,
            };
            const types2 = {
                OrderItem: [
                    { name: 'seller', type: 'address' },
                    { name: 'itemId', type: 'string' },
                    { name: 'tokenId', type: 'uint256' },
                    { name: 'itemPrice', type: 'uint256' },
                    { name: 'itemAddress', type: 'address' },
                    { name: 'nonce', type: 'string' },
                ],
            };
            const orderItem2 = {
                seller: user.address,
                itemId: '99',
                tokenId: BigNumber.from(1),
                itemPrice: ethers.utils.parseEther('100'),
                itemAddress: NFTContract.address,
                nonce: nonce2,
            };

            const signature2 = await hashOrderItem(types2, auth2, orderItem2);
            const tx2 = await MarketplaceContract.connect(user).offer(signature2);
            await tx2.wait();

            await MarketplaceContract.connect(deployer).setFeesCollector(
                feesCollector.address
            );

            await RUNNOWContract.connect(buyer).approve(
                MarketplaceContract.address,
                ethers.utils.parseEther('100')
            );

            const balanceOfFeesCollector1 = await RUNNOWContract.connect(deployer).balanceOf(feesCollector.address);

            // Buy box
            const nonce3 = uuidv4();
            const auth3 = {
                signer: deployer,
                contract: MarketplaceContract.address,
            };
            const types3 = {
                CartItem: [
                    { name: 'buyer', type: 'address' },
                    { name: 'itemId', type: 'string' },
                    { name: 'feesCollectorCutPerMillion', type: 'uint256' },
                    { name: 'coinPrice', type: 'uint256' },
                    { name: 'tokenPrice', type: 'uint256' },
                    { name: 'tokenAddress', type: 'address' },
                    { name: 'nonce', type: 'string' },
                ],
            };
            const cartItem3 = {
                buyer: buyer.address,
                itemId: orderItem2.itemId,
                feesCollectorCutPerMillion: BigNumber.from(5 / 100 * 1_000_000), // 5%
                coinPrice: ethers.utils.parseEther('0'),
                tokenPrice: ethers.utils.parseEther('100'),
                tokenAddress: RUNNOWContract.address,
                nonce: nonce3,
            };

            const signature3 = await hashOrderItem(types3, auth3, cartItem3);
            const tx3 = await MarketplaceContract.connect(buyer).buy(signature3);
            const receipt = await tx3.wait();
            const event = receipt.events?.filter((x: any) => {
                return x.event === 'Buy';
            });
            const balanceOfFeesCollector2 = await RUNNOWContract.connect(deployer).balanceOf(feesCollector.address);
            const diff = balanceOfFeesCollector2 - balanceOfFeesCollector1;

            assert(diff > ethers.utils.parseEther('4.8').toBigInt());
            expect(event[0].args.buyer).to.equal(buyer.address);
            expect(event[0].args.itemId).to.equal(orderItem2.itemId);
        });

        it('returns right data - Native coin', async () => {
            await RUNNOWContract.connect(user).approve(
                NFTContract.address,
                ethers.utils.parseEther('100')
            );

            // Mint Box
            const nonce1 = uuidv4();
            const auth1 = {
                signer: deployer,
                contract: NFTContract.address,
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
            const tx = await NFTContract.connect(user).redeem(signature1);
            await tx.wait();

            await NFTContract.connect(user).setApprovalForAll(
                MarketplaceContract.address,
                true
            );

            // Offer box
            const nonce2 = uuidv4();
            const auth2 = {
                signer: deployer,
                contract: MarketplaceContract.address,
            };
            const types2 = {
                OrderItem: [
                    { name: 'seller', type: 'address' },
                    { name: 'itemId', type: 'string' },
                    { name: 'tokenId', type: 'uint256' },
                    { name: 'itemPrice', type: 'uint256' },
                    { name: 'itemAddress', type: 'address' },
                    { name: 'nonce', type: 'string' },
                ],
            };
            const orderItem2 = {
                seller: user.address,
                itemId: '99',
                tokenId: BigNumber.from(1),
                itemPrice: ethers.utils.parseEther('100'),
                itemAddress: NFTContract.address,
                nonce: nonce2,
            };

            const signature2 = await hashOrderItem(types2, auth2, orderItem2);
            const tx2 = await MarketplaceContract.connect(user).offer(signature2);
            await tx2.wait();

            await MarketplaceContract.connect(deployer).setFeesCollector(
                feesCollector.address
            );

            await RUNNOWContract.connect(buyer).approve(
                MarketplaceContract.address,
                ethers.utils.parseEther('100')
            );

            const balanceOfFeesCollector1 = await ethers.provider.getBalance(feesCollector.address);

            // Buy box
            const nonce3 = uuidv4();
            const auth3 = {
                signer: deployer,
                contract: MarketplaceContract.address,
            };
            const types3 = {
                CartItem: [
                    { name: 'buyer', type: 'address' },
                    { name: 'itemId', type: 'string' },
                    { name: 'feesCollectorCutPerMillion', type: 'uint256' },
                    { name: 'coinPrice', type: 'uint256' },
                    { name: 'tokenPrice', type: 'uint256' },
                    { name: 'tokenAddress', type: 'address' },
                    { name: 'nonce', type: 'string' },
                ],
            };
            const cartItem3 = {
                buyer: buyer.address,
                itemId: orderItem2.itemId,
                feesCollectorCutPerMillion: BigNumber.from(5 / 100 * 1_000_000), // 5%
                coinPrice: ethers.utils.parseEther('100'),
                tokenPrice: ethers.utils.parseEther('0'),
                tokenAddress: RUNNOWContract.address,
                nonce: nonce3,
            };

            const signature3 = await hashOrderItem(types3, auth3, cartItem3);
            const tx3 = await MarketplaceContract.connect(buyer).buy(signature3, {
                value: ethers.utils.parseEther('100')
            });
            const receipt = await tx3.wait();
            const event = receipt.events?.filter((x: any) => {
                return x.event === 'Buy';
            });
            const balanceOfFeesCollector2 = await ethers.provider.getBalance(feesCollector.address);
            const diff = balanceOfFeesCollector2.toBigInt() - balanceOfFeesCollector1.toBigInt();

            assert(diff > ethers.utils.parseEther('4.8').toBigInt());
            expect(event[0].args.buyer).to.equal(buyer.address);
            expect(event[0].args.itemId).to.equal(orderItem2.itemId);
        });
    });

    describe('Withdraw', () => {
        context('when success', async () => {
            it('returns right data', async () => {
                await RUNNOWContract.connect(user).approve(
                    NFTContract.address,
                    ethers.utils.parseEther('25')
                );
                const nonce1 = uuidv4();
                const auth1 = {
                    signer: deployer,
                    contract: NFTContract.address,
                };
                const types1 = {
                    ItemVoucherStruct: [
                        { name: 'redeemer', type: 'address' },
                        { name: 'itemId', type: 'string' },
                        { name: 'itemClass', type: 'string' },
                        { name: 'coinPrice', type: 'uint256' },
                        { name: 'tokenPrice', type: 'uint256' },
                        { name: 'tokenAddress', type: 'address' },
                        { name: 'nonce', type: 'string' },
                    ],
                };
                const voucher1 = {
                    redeemer: user.address,
                    itemId: '123',
                    itemClass: 'box',
                    coinPrice: ethers.utils.parseEther('0'),
                    tokenPrice: ethers.utils.parseEther('25'),
                    tokenAddress: RUNNOWContract.address,
                    nonce: nonce1,
                };
                const signature1 = await createVoucher(types1, auth1, voucher1);
                const tx = await NFTContract.connect(user).redeem(signature1);
                await tx.wait();

                await NFTContract.connect(user).setApprovalForAll(
                    MarketplaceContract.address,
                    true
                );

                const nonce2 = uuidv4();
                const auth2 = {
                    signer: deployer,
                    contract: MarketplaceContract.address,
                };
                const types2 = {
                    OrderItem: [
                        { name: 'seller', type: 'address' },
                        { name: 'itemId', type: 'string' },
                        { name: 'tokenId', type: 'uint256' },
                        { name: 'itemPrice', type: 'uint256' },
                        { name: 'itemAddress', type: 'address' },
                        { name: 'nonce', type: 'string' },
                    ],
                };
                const orderItem2 = {
                    seller: user.address,
                    itemId: '99',
                    tokenId: BigNumber.from(1),
                    itemPrice: ethers.utils.parseEther('100'),
                    itemAddress: NFTContract.address,
                    nonce: nonce2,
                };

                const signature2 = await hashOrderItem(types2, auth2, orderItem2);
                const tx2 = await MarketplaceContract.connect(user).offer(signature2);
                await tx2.wait();

                const tx3 = await MarketplaceContract.connect(user).withdraw(orderItem2.itemId);
                const receipt = await tx3.wait();

                const event = receipt.events?.filter((x: any) => {
                    return x.event === 'Withdraw';
                });

                expect(event[0].args.owner).to.equal(user.address);
                expect(event[0].args.itemId).to.equal(orderItem2.itemId);
                expect(event[0].args.itemAddress).to.equal(NFTContract.address);
            });
        });
    });
});
