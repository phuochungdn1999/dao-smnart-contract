import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from "uuid";
import deployRUNNOWUpgradeable from "../../scripts/coin/deployRUNNOW";
import deployNFTUpgradeable from "../../scripts/nft/deployNFT";
import upgradeNFTUpgradeable from "../../scripts/nft/upgradeNFT";
import { createVoucher } from "../../utils/hashVoucher";

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let game: SignerWithAddress;
let account: SignerWithAddress;
let NFTContract: Contract;
let RUNNOWContract: Contract;

describe("NFT", () => {
  beforeEach(async () => {
    [deployer, user, game, account] = await ethers.getSigners();
    RUNNOWContract = await deployRUNNOWUpgradeable(deployer);
    NFTContract = await deployNFTUpgradeable(deployer);

    await RUNNOWContract.connect(deployer).transfer(
      user.address,
      ethers.utils.parseEther("10000")
    );
  });

  describe("V2", async () => {
    it("Upgrade NFT contract and open box", async () => {
      //   const NFTContract = await upgradeNFTUpgradeable(
      //     NFTContract.address,
      //     deployer
      //   );

      // Mint box
      await RUNNOWContract.connect(deployer).approve(
        NFTContract.address,
        ethers.utils.parseEther("25")
      );
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
          { name: "nonce", type: "string" },
        ],
      };
      const voucher = {
        id: "123",
        itemType: "box",
        extraType: "",
        price: ethers.utils.parseEther("25"),
        nonce: nonce,
      };
      const signature = await createVoucher(types, auth, voucher);
      const tx = await NFTContract.connect(deployer).redeem(signature, {
        value: ethers.utils.parseEther("25"),
      });
      await tx.wait();

      // Open starter box
      const nonce2 = uuidv4();
      const auth2 = {
        signer: deployer,
        contract: NFTContract.address,
      };
      const types2 = {
        StarterBoxStruct: [
          { name: "walletAddress", type: "address" },
          { name: "id", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "numberTokens", type: "uint256" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucher2 = {
        walletAddress: user.address,
        id: "123",
        tokenId: BigNumber.from(1),
        numberTokens: BigNumber.from(2),
        nonce: nonce2,
      };
      const signature2 = await createVoucher(types2, auth2, voucher2);
      const tx2 = await NFTContract.connect(user).openStarterBox(signature2);
      const receipt2 = await tx2.wait();
      const event2 = receipt2.events?.filter((x: any) => {
        return x.event === "OpenStarterBoxEvent";
      });

      expect(event2[0].args.user).to.equal(user.address);
    });

    it("Upgrade NFT contract and mint from game", async () => {
      //   const NFTContract = await upgradeNFTUpgradeable(
      //     NFTContract.address,
      //     deployer
      //   );

      await NFTContract.connect(deployer).setGameAddress(game.address);

      // Mint from game
      const tx1 = await NFTContract.connect(game).mintFromGame(
        user.address,
        "123",
        "box",
        ""
      );
      const receipt1 = await tx1.wait();
      const event1 = receipt1.events?.filter((x: any) => {
        return x.event === "MintFromGameEvent";
      });

      expect(event1[0].args.id).to.equal("123");
    });

    it("Upgrade NFT contract and mint batch", async () => {
      //   const NFTContract = await upgradeNFTUpgradeable(
      //     NFTContract.address,
      //     deployer
      //   );

      await NFTContract.connect(deployer).setGameAddress(game.address);

      const to = [];
      const ids = [];
      const itemTypes = [];
      const extraTypes = [];
      const nonces = [];

      for (let i = 0; i < 100; i++) {
        to.push(account.address);
        ids.push(`id${i}`);
        itemTypes.push(`id${i}`);
        extraTypes.push(`id${i}`);
        nonces.push(`id${i}`);
      }
      // Mint from game
      const tx1 = await NFTContract.connect(deployer).mintBatch(
        to,
        ids,
        itemTypes,
        extraTypes,
        nonces
      );
      await tx1.wait();
      expect(
        await NFTContract.connect(deployer).balanceOf(account.address)
      ).to.equal("100");
    });
  });
});
