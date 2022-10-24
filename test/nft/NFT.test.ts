import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from "uuid";
import deployNFTUpgradeable from "../../scripts/nft/deployNFT";
import deployGameUpgradeable from "../../scripts/game/deployGame";
import { createVoucher } from "../../utils/hashVoucher";
import deployBlacklistUpgradeable from "../../scripts/blacklist/deployBlacklist";

let deployer: SignerWithAddress;
let game: SignerWithAddress;
let account: SignerWithAddress;
let NFTContract: Contract;
let GameContract: Contract;
let banContract: Contract;

describe("NFT", () => {
  beforeEach(async () => {
    [deployer, game, account] = await ethers.getSigners();
    NFTContract = await deployNFTUpgradeable(deployer);
    banContract = await deployBlacklistUpgradeable(deployer);
    GameContract = await deployGameUpgradeable(deployer);

    await NFTContract.connect(deployer).setBanContractAddress(
      banContract.address
    );

    await NFTContract.connect(deployer).setOperator(deployer.address);
    await NFTContract.connect(deployer).setMintBatchAdress(deployer.address);
    await NFTContract.connect(deployer).setGameAddress(GameContract.address);
  });

  describe("V2", async () => {
    it("Reedem box", async () => {
      // Mint box
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
      expect(
        await await NFTContract.connect(deployer).balanceOf(deployer.address)
      ).to.equal(1);
    });

    it("Mint batch", async () => {
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
