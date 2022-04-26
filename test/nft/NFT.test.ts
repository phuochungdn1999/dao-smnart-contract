/* eslint-disable node/no-missing-import */
/* eslint-disable no-unused-vars */
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from "uuid";
import deployRUNNOWUpgradeable from "../../scripts/coin/deployRUNNOW";
import deployNFTUpgradeable from "../../scripts/nft/deployNFT";
import { createVoucher } from "../../utils/hashVoucher";

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let ERC721Instance: Contract;
let RUNNOWContract: Contract;

describe("NFT", () => {
  beforeEach(async () => {
    [deployer, user] = await ethers.getSigners();
    RUNNOWContract = await deployRUNNOWUpgradeable();
    ERC721Instance = await deployNFTUpgradeable();

    await RUNNOWContract.connect(deployer).transfer(
      user.address,
      ethers.utils.parseEther("10000")
    );
  });

  it("Mint a box, premint, craft NFT by token ERC-20", async () => {
    await RUNNOWContract.connect(user).approve(
      ERC721Instance.address,
      ethers.utils.parseEther("25")
    );
    const nonce = uuidv4();
    const auth = {
      signer: deployer,
      contract: ERC721Instance.address,
    };
    const types = {
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
    const voucher = {
      redeemer: user.address,
      itemId: "123",
      itemClass: "box",
      coinPrice: ethers.utils.parseEther("0"),
      tokenPrice: ethers.utils.parseEther("25"),
      tokenAddress: RUNNOWContract.address,
      nonce: nonce,
    };
    const signature = await createVoucher(types, auth, voucher);
    const tx = await ERC721Instance.connect(user).redeem(signature);
    const receipt = await tx.wait();
    const event = receipt.events?.filter((x: any) => {
      return x.event === "Redeem";
    });

    expect(event[0].args.voucher.itemId).to.equal(voucher.itemId);
  });

  it("Mint a box, premint, craft NFT by native coin", async () => {
    const nonce = uuidv4();
    const auth = {
      signer: deployer,
      contract: ERC721Instance.address,
    };
    const types = {
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
    const voucher = {
      redeemer: user.address,
      itemId: "12345",
      itemClass: "box",
      coinPrice: ethers.utils.parseEther("1"),
      tokenPrice: ethers.utils.parseEther("0"),
      tokenAddress: RUNNOWContract.address,
      nonce: nonce,
    };
    const signature = await createVoucher(types, auth, voucher);
    const tx = await ERC721Instance.connect(user).redeem(signature, {
      value: ethers.utils.parseEther("1")
    });
    const receipt = await tx.wait();
    const event = receipt.events?.filter((x: any) => {
      return x.event === "Redeem";
    });

    expect(event[0].args.voucher.itemId).to.equal(voucher.itemId);
  });

  it("Open a box", async () => {
    // Mint box
    await RUNNOWContract.connect(user).approve(
      ERC721Instance.address,
      ethers.utils.parseEther("25")
    );
    const nonce1 = uuidv4();
    const auth1 = {
      signer: deployer,
      contract: ERC721Instance.address,
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
    const tx = await ERC721Instance.connect(user).redeem(signature1);
    await tx.wait();

    // Open box
    const nonce2 = uuidv4();
    const auth2 = {
      signer: deployer,
      contract: ERC721Instance.address,
    };
    const types2 = {
      StarterBox: [
        { name: "redeemer", type: "address" },
        { name: "boxId", type: "string" },
        { name: "boxTokenId", type: "uint256" },
        { name: "numberTokens", type: "uint256" },
        { name: "nonce", type: "string" },
      ],
    };
    const voucher2 = {
      redeemer: user.address,
      boxId: "123",
      boxTokenId: BigNumber.from(1),
      numberTokens: BigNumber.from(2),
      nonce: nonce2,
    };
    const signature2 = await createVoucher(types2, auth2, voucher2);
    const tx2 = await ERC721Instance.connect(user).openStarterBox(signature2);
    const receipt = await tx2.wait();
    const event = receipt.events?.filter((x: any) => {
      return x.event === "MintedStarterBox";
    });

    expect(event[0].args.from).to.equal(user.address);
  });
});
