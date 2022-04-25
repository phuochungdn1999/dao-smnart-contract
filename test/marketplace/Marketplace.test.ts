import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { BigNumber, Contract } from 'ethers';
import { ethers } from 'hardhat';
import { v4 as uuidv4 } from "uuid";
import deployRUNNOWUpgradeable from '../../scripts/coin/deployRUNNOW';
import deployMarketplaceUpgradeable from '../../scripts/marketplace/deployMarketplace';
import deployNFTUpgradeable from '../../scripts/nft/deployNFT';
import { hashOrderItem } from '../../utils/hashMarketplaceItem';
import { createVoucher } from '../../utils/hashVoucher';


let deployer: SignerWithAddress;
let user: SignerWithAddress;
let buyer: SignerWithAddress;
let secret: SignerWithAddress;
let RUNNOWContract: Contract;
let NFTContract: Contract;
describe("Marketplace", async () => {
    beforeEach(async () => {
        [deployer, user, buyer, secret] = await ethers.getSigners();
        console.log(buyer.address)
        console.log('1231231231312312312312')
        RUNNOWContract = await deployRUNNOWUpgradeable();
        NFTContract = await deployNFTUpgradeable();
        await RUNNOWContract.connect(deployer).transfer(user.address, ethers.utils.parseEther("1000"));
        await RUNNOWContract.connect(deployer).transfer(buyer.address, ethers.utils.parseEther("1000"));

    });

    it("Deploy marketplace proxy contract ", async () => {
        // Deploy marketplace proxy contract
        const Marketplace = await deployMarketplaceUpgradeable();
        // Check feesCollector address
        const feesCollector = await Marketplace.connect(deployer).feesCollector();
        expect(feesCollector).to.equal(deployer.address);

        // Check offer function
        // User approve 25 ether for NFT contract
        await RUNNOWContract.connect(user).approve(
            NFTContract.address,
            ethers.utils.parseEther("25")
        );

        // Creare signature for redeem
        const nonce1 = uuidv4();
        const auth1 = {
            signer: deployer,
            contract: NFTContract.address,
        };
        const types1 = {
            NFTVoucher: [
                { name: "redeemer", type: "address" },
                { name: "itemId", type: "string" },
                { name: "itemClass", type: "string" },
                { name: "coinPrice", type: "uint256" },
                { name: "tokenPrice", type: "uint256" },
                { name: "tokenAddress", type: "address" },
                { name: "nonce", type: "string" },
            ],
        };
        const voucher1 = {
            redeemer: user.address,
            itemId: "123",
            itemClass: "box",
            coinPrice: ethers.utils.parseEther("0"),
            tokenPrice: ethers.utils.parseEther("25"),
            tokenAddress: RUNNOWContract.address,
            nonce: nonce1,
        };
        const signature1 = await createVoucher(types1, auth1, voucher1);

        // Redeem 1 NFT
        const tx = await NFTContract.connect(user).redeem(signature1);
        await tx.wait();



        //User approve all NFT for marketplace
        await NFTContract.connect(user).setApprovalForAll(
            Marketplace.address,
            true
        );

        //Create signature for redeem
        const nonce2 = uuidv4();
        const auth2 = {
            signer: deployer,
            contract: Marketplace.address,
        };
        const types2 = {
            OrderItem: [
                { name: "seller", type: "address" },
                { name: "itemId", type: "string" },
                { name: "tokenId", type: "uint256" },
                { name: "itemPrice", type: "uint256" },
                { name: "itemAddress", type: "address" },
                { name: "nonce", type: "string" },
            ],
        };
        const orderItem2 = {
            seller: user.address,
            itemId: "99",
            tokenId: BigNumber.from(1),
            itemPrice: ethers.utils.parseEther("100"),
            itemAddress: NFTContract.address,
            nonce: nonce2,
        };

        const signature2 = await hashOrderItem(types2, auth2, orderItem2);

        //Offer a NFT
        const tx2 = await Marketplace.connect(user).offer(signature2);
        const receipt = await tx2.wait();

        const event = receipt.events?.filter((x: any) => {
            return x.event === "Offer";
        });

        expect(event[0].args.seller).to.equal(user.address);
        expect(event[0].args.itemId).to.equal(orderItem2.itemId);
        expect(event[0].args.itemAddress).to.equal(NFTContract.address);
    });
});
