import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from 'uuid';
import deployRUNNOWUpgradeable from '../../scripts/coin/deployRUNNOW';
import deployNFTUpgradeable from '../../scripts/nft/deployNFT';
import upgradeNFTUpgradeable from '../../scripts/nft/upgradeNFT';
import { createVoucher } from '../../utils/hashVoucher';

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let NFTConstract: Contract;
let RUNNOWContract: Contract;

describe('NFT', () => {
    beforeEach(async () => {
        [deployer, user] = await ethers.getSigners();
        RUNNOWContract = await deployRUNNOWUpgradeable(deployer);
        NFTConstract = await deployNFTUpgradeable(deployer);

        await RUNNOWContract.connect(deployer).transfer(
            user.address,
            ethers.utils.parseEther('10000')
        );
    });

    it('Premint by token ERC-20', async () => {
        // Mint box
        await RUNNOWContract.connect(user).approve(
            NFTConstract.address,
            ethers.utils.parseEther('25')
        );
        const nonce = uuidv4();
        const auth = {
            signer: deployer,
            contract: NFTConstract.address,
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
            id: '123',
            itemType: 'box',
            price: ethers.utils.parseEther('25'),
            priceTokenAddress: RUNNOWContract.address,
            nonce: nonce,
        };
        const signature = await createVoucher(types, auth, voucher);
        const tx = await NFTConstract.connect(user).redeem(signature);
        const receipt = await tx.wait();
        const event = receipt.events?.filter((x: any) => {
            return x.event === 'RedeemEvent';
        });

        expect(event[0].args.id).to.equal(voucher.id);
    });

    it('Upgrade NFT contract and open box', async () => {
        const NFTConstractV2 = await upgradeNFTUpgradeable(NFTConstract.address, deployer);

        // Mint box
        await RUNNOWContract.connect(user).approve(
            NFTConstract.address,
            ethers.utils.parseEther('25')
        );
        const nonce = uuidv4();
        const auth = {
            signer: deployer,
            contract: NFTConstract.address,
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
            id: '123',
            itemType: 'box',
            price: ethers.utils.parseEther('25'),
            priceTokenAddress: RUNNOWContract.address,
            nonce: nonce,
        };
        const signature = await createVoucher(types, auth, voucher);
        const tx = await NFTConstract.connect(user).redeem(signature);
        await tx.wait();

        // Open starter box
        const nonce2 = uuidv4();
        const auth2 = {
            signer: deployer,
            contract: NFTConstract.address,
        };
        const types2 = {
            StarterBoxStruct: [
                { name: 'id', type: 'string' },
                { name: 'tokenId', type: 'uint256' },
                { name: 'numberTokens', type: 'uint256' },
                { name: 'nonce', type: 'string' },
            ],
        };
        const voucher2 = {
            id: '123',
            tokenId: BigNumber.from(1),
            numberTokens: BigNumber.from(2),
            nonce: nonce2,
        };
        const signature2 = await createVoucher(types2, auth2, voucher2);
        const tx2 = await NFTConstractV2.connect(user).openStarterBox(signature2);
        const receipt2 = await tx2.wait();
        const event2 = receipt2.events?.filter((x: any) => {
            return x.event === 'OpenStarterBoxEvent';
        });

        expect(event2[0].args.user).to.equal(user.address);
    });
});
