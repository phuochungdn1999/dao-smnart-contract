import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from "uuid";
import deployBlacklistUpgradeable from "../../scripts/blacklist/deployBlacklist";
import deployRUNGEMUpgradeable from "../../scripts/coin/deployRUNGEM";
import deployMarketplaceUpgradeable from "../../scripts/marketplace/deployMarketplace";
import deployNFTUpgradeable from "../../scripts/nft/deployNFT";
import { hashOrderItem } from "../../utils/hashMarketplaceItem";
import { createVoucher } from "../../utils/hashVoucher";

const provider = ethers.getDefaultProvider();

let deployer: SignerWithAddress;
let buyer: SignerWithAddress;
let feesCollector: SignerWithAddress;
let NFTContract: Contract;
let MarketplaceContract: Contract;
let RungemContract: Contract;
const nullAddress = "0x0000000000000000000000000000000000000000";
let banContract: Contract;

describe("Marketplace", async () => {
  beforeEach(async () => {
    [deployer, buyer, feesCollector] = await ethers.getSigners();
    NFTContract = await deployNFTUpgradeable(deployer);
    MarketplaceContract = await deployMarketplaceUpgradeable(deployer);
    RungemContract = await deployRUNGEMUpgradeable(deployer);
    NFTContract = await deployNFTUpgradeable(deployer);
    banContract = await deployBlacklistUpgradeable(deployer);

    await NFTContract.connect(deployer).setBanContractAddress(
      banContract.address
    );

    await NFTContract.connect(deployer).setOperator(deployer.address);

    await MarketplaceContract.connect(deployer).setBanContractAddress(
      banContract.address
    );

    await MarketplaceContract.connect(deployer).setOperator(deployer.address);
    await MarketplaceContract.connect(deployer).setAllowedToken(
      nullAddress,
      true
    );

    await MarketplaceContract.connect(deployer).setAllowedToken(
      RungemContract.address,
      true
    );

    await RungemContract.connect(deployer).mint(
      deployer.address,
      ethers.utils.parseEther("10000000000")
    );
  });

  describe("Offer", () => {
    it("Offer, Withdraw NFT", async () => {
      const nonce = uuidv4();
      const auth = {
        signer: deployer,
        contract: NFTContract.address,
      };
      const types = {
        ItemVoucherStruct: [
          { name: "id", type: "string" },
          { name: "itemType", type: "string" },
          { name: "extraType", type: "string" },
          { name: "price", type: "uint256" },
          { name: "amount", type: "uint256" },
          { name: "tokenAddress", type: "address" },
          { name: "receiver", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucher = {
        id: "123123",
        itemType: "box",
        extraType: "",
        price: ethers.utils.parseEther("1"),
        amount: 1,
        tokenAddress: "0x0000000000000000000000000000000000000000",
        receiver: deployer.address,
        nonce: nonce,
      };
      const signature = await createVoucher(types, auth, voucher);
      // console.log("signature: ",signature)
      const tx = await NFTContract.connect(deployer).redeem(signature, {
        value: ethers.utils.parseEther("1"),
      });
      await tx.wait();
      expect(await await NFTContract.connect(deployer).ownerOf(1)).to.equal(
        deployer.address
      );

      const txApprove = await NFTContract.connect(deployer).approve(
        MarketplaceContract.address,
        1
      );
      await txApprove.wait();

      // Offer

      const nonce2 = uuidv4();
      const auth2 = {
        signer: deployer,
        contract: MarketplaceContract.address,
      };

      const types2 = {
        OrderItemStruct: [
          { name: "walletAddress", type: "address" },
          { name: "id", type: "string" },
          { name: "itemType", type: "string" },
          { name: "extraType", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "itemAddress", type: "address" },
          { name: "price", type: "uint256[]" },
          { name: "tokenAddress", type: "address[]" },
          { name: "useBUSD", type: "bool" },
          { name: "nonce", type: "string" },
        ],
      };
      const listItemPrice = [ethers.utils.parseEther("100")];
      const price = listItemPrice.map((i: any) => {
        return i?.toLocaleString("fullwide", { useGrouping: false });
      });
      const orderItem2 = {
        walletAddress: deployer.address,
        id: "123",
        itemType: "box",
        extraType: "",
        tokenId: 1,
        itemAddress: NFTContract.address,
        price: price,
        tokenAddress: [nullAddress],
        useBUSD: true,
        nonce: nonce2,
      };

      const signature2 = await hashOrderItem(types2, auth2, orderItem2);
      const tx2 = await MarketplaceContract.connect(deployer).offer(signature2);
      const receipt = await tx2.wait();
      const event = receipt.events?.filter((x: any) => {
        return x.event === "OfferEvent";
      });

      expect(event[0].args.owner).to.equal(deployer.address);
      expect(event[0].args.id).to.equal(orderItem2.id);

      // Withdraw
      const tx3 = await MarketplaceContract.connect(deployer).withdraw(
        orderItem2.id
      );
      await tx3.wait();

      expect(
        await NFTContract.connect(deployer).balanceOf(deployer.address)
      ).to.equal(1);
    });
  });

  describe("Buy", () => {
    it("Buy NFT", async () => {
      const nonce = uuidv4();
      const auth = {
        signer: deployer,
        contract: NFTContract.address,
      };
      const types = {
        ItemVoucherStruct: [
          { name: "id", type: "string" },
          { name: "itemType", type: "string" },
          { name: "extraType", type: "string" },
          { name: "price", type: "uint256" },
          { name: "amount", type: "uint256" },
          { name: "tokenAddress", type: "address" },
          { name: "receiver", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucher = {
        id: "123123",
        itemType: "box",
        extraType: "",
        price: ethers.utils.parseEther("1"),
        amount: 1,
        tokenAddress: "0x0000000000000000000000000000000000000000",
        receiver: deployer.address,
        nonce: nonce,
      };
      const signature = await createVoucher(types, auth, voucher);
      // console.log("signature: ",signature)
      const tx = await NFTContract.connect(deployer).redeem(signature, {
        value: ethers.utils.parseEther("1"),
      });
      await tx.wait();
      expect(await await NFTContract.connect(deployer).ownerOf(1)).to.equal(
        deployer.address
      );

      const txApprove = await NFTContract.connect(deployer).approve(
        MarketplaceContract.address,
        1
      );
      await txApprove.wait();

      // Offer
      const nonce2 = uuidv4();
      const auth2 = {
        signer: deployer,
        contract: MarketplaceContract.address,
      };

      const types2 = {
        OrderItemStruct: [
          { name: "walletAddress", type: "address" },
          { name: "id", type: "string" },
          { name: "itemType", type: "string" },
          { name: "extraType", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "itemAddress", type: "address" },
          { name: "price", type: "uint256[]" },
          { name: "tokenAddress", type: "address[]" },
          { name: "useBUSD", type: "bool" },
          { name: "nonce", type: "string" },
        ],
      };
      const listItemPrice = [ethers.utils.parseEther("100")];
      const price = listItemPrice.map((i: any) => {
        return i?.toLocaleString("fullwide", { useGrouping: false });
      });
      const orderItem2 = {
        walletAddress: deployer.address,
        id: "123",
        itemType: "box",
        extraType: "",
        tokenId: 1,
        itemAddress: NFTContract.address,
        price: price,
        tokenAddress: [nullAddress],
        useBUSD: true,
        nonce: nonce2,
      };

      const signature2 = await hashOrderItem(types2, auth2, orderItem2);
      const tx2 = await MarketplaceContract.connect(deployer).offer(signature2);
      await tx2.wait();

      const feesCollectorCutPerMillion = BigNumber.from(
        Math.ceil((5 / 100) * 1_000_000)
      );
      await MarketplaceContract.connect(deployer).setFeesCollectorAddress(
        feesCollector.address
      );
      await MarketplaceContract.connect(deployer).setFeesCollectorCutPerMillion(
        feesCollectorCutPerMillion
      );

      const balanceOfFeesCollector1 = await provider.getBalance(
        feesCollector.address
      );

      // Buy

      const nonce3 = uuidv4();
      const auth3 = {
        signer: deployer,
        contract: MarketplaceContract.address,
      };

      const types3 = {
        BuyItemStruct: [
          { name: "id", type: "string" },
          { name: "tokenAddress", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "useBUSD", type: "bool" },
          { name: "nonce", type: "string" },
        ],
      };

      const buyItem = {
        id: "123",
        tokenAddress: nullAddress,
        amount: ethers.utils.parseEther("100"),
        useBUSD: true,
        nonce: nonce3,
      };

      const signature3 = await hashOrderItem(types3, auth3, buyItem);
      const tx3 = await MarketplaceContract.connect(buyer).buy(signature3, {
        value: ethers.utils.parseEther("100"),
      });
      await tx3.wait();
      const receipt = await tx3.wait();
      const event = receipt.events?.filter((x: any) => {
        return x.event === "BuyEvent";
      });
      const balanceOfFeesCollector2 = await provider.getBalance(
        feesCollector.address
      );
      const diff = balanceOfFeesCollector2.sub(balanceOfFeesCollector1);

      assert(diff.lt(ethers.utils.parseEther("4.8")));
      expect(event[0].args.buyer).to.equal(buyer.address);
      expect(event[0].args.id).to.equal(orderItem2.id);
    });
  });

  describe("Buy with RunGem", () => {
    it("Buy", async () => {
      const nonce = uuidv4();
      const auth = {
        signer: deployer,
        contract: NFTContract.address,
      };
      const types = {
        ItemVoucherStruct: [
          { name: "id", type: "string" },
          { name: "itemType", type: "string" },
          { name: "extraType", type: "string" },
          { name: "price", type: "uint256" },
          { name: "amount", type: "uint256" },
          { name: "tokenAddress", type: "address" },
          { name: "receiver", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucher = {
        id: "123123",
        itemType: "box",
        extraType: "",
        price: ethers.utils.parseEther("1"),
        amount: 1,
        tokenAddress: "0x0000000000000000000000000000000000000000",
        receiver: deployer.address,
        nonce: nonce,
      };
      const signature = await createVoucher(types, auth, voucher);
      // console.log("signature: ",signature)
      const tx = await NFTContract.connect(deployer).redeem(signature, {
        value: ethers.utils.parseEther("1"),
      });
      await tx.wait();
      expect(await await NFTContract.connect(deployer).ownerOf(1)).to.equal(
        deployer.address
      );

      const txApprove = await NFTContract.connect(deployer).approve(
        MarketplaceContract.address,
        1
      );
      await txApprove.wait();

      // Offer
      const nonce2 = uuidv4();
      const auth2 = {
        signer: deployer,
        contract: MarketplaceContract.address,
      };

      const types2 = {
        OrderItemStruct: [
          { name: "walletAddress", type: "address" },
          { name: "id", type: "string" },
          { name: "itemType", type: "string" },
          { name: "extraType", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "itemAddress", type: "address" },
          { name: "price", type: "uint256[]" },
          { name: "tokenAddress", type: "address[]" },
          { name: "useBUSD", type: "bool" },
          { name: "nonce", type: "string" },
        ],
      };
      const listItemPrice = [
        ethers.utils.parseEther("100"),
        ethers.utils.parseEther("100"),
      ];
      const price = listItemPrice.map((i: any) => {
        return i?.toLocaleString("fullwide", { useGrouping: false });
      });
      const orderItem2 = {
        walletAddress: deployer.address,
        id: "123",
        itemType: "box",
        extraType: "",
        tokenId: 1,
        itemAddress: NFTContract.address,
        price: price,
        tokenAddress: [nullAddress, RungemContract.address],
        useBUSD: true,
        nonce: nonce2,
      };

      const signature2 = await hashOrderItem(types2, auth2, orderItem2);
      const tx2 = await MarketplaceContract.connect(deployer).offer(signature2);
      await tx2.wait();

      const feesCollectorCutPerMillion = BigNumber.from(
        Math.ceil((5 / 100) * 1_000_000)
      );
      await MarketplaceContract.connect(deployer).setFeesCollectorAddress(
        feesCollector.address
      );
      await MarketplaceContract.connect(deployer).setFeesCollectorCutPerMillion(
        feesCollectorCutPerMillion
      );

      await RungemContract.connect(deployer).transfer(
        buyer.address,
        ethers.utils.parseEther("10000")
      );

      await RungemContract.connect(buyer).approve(
        MarketplaceContract.address,
        ethers.utils.parseEther("10000")
      );

      // Buy
      const nonce3 = uuidv4();
      const auth3 = {
        signer: deployer,
        contract: MarketplaceContract.address,
      };

      const types3 = {
        BuyItemStruct: [
          { name: "id", type: "string" },
          { name: "tokenAddress", type: "address" },
          { name: "amount", type: "uint256" },
          { name: "useBUSD", type: "bool" },
          { name: "nonce", type: "string" },
        ],
      };

      const buyItem = {
        id: "123",
        tokenAddress: RungemContract.address,
        amount: ethers.utils.parseEther("100"),
        useBUSD: true,
        nonce: nonce3,
      };

      const signature3 = await hashOrderItem(types3, auth3, buyItem);
      const tx3 = await MarketplaceContract.connect(buyer).buy(signature3);
      await tx3.wait();

      expect(
        await NFTContract.connect(deployer).balanceOf(buyer.address)
      ).to.equal(1);
    });
  });
});
