import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { assert, expect } from "chai";
import { Contract } from "ethers";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from "uuid";
import deployBlacklistUpgradeable from "../../scripts/blacklist/deployBlacklist";
import deployRUNNOWUpgradeable from "../../scripts/coin/deployRUNNOW";
import deployNFTUpgradeable from "../../scripts/nft/deployNFT";
import deployVaultUpgradeable from "../../scripts/vault/deployVault";
import { createVoucher } from "../../utils/hashVoucher";

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let NFTContract: Contract;
let vaultContract: Contract;
let banContract: Contract;

describe("Vault", () => {
  beforeEach(async () => {
    [deployer, user] = await ethers.getSigners();
    NFTContract = await deployNFTUpgradeable(deployer);
    vaultContract = await deployVaultUpgradeable(deployer);
    banContract = await deployBlacklistUpgradeable(deployer);
    await NFTContract.connect(deployer).setBanContractAddress(
      banContract.address
    );
    await NFTContract.connect(deployer).setOperator(deployer.address);
    await vaultContract.connect(deployer).setOperator(deployer.address);
  });
  describe("Charge fee", async () => {
    it("Charge Transfer NFT", async () => {
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
      const txApprove = await NFTContract.connect(deployer).approve(
        vaultContract.address,
        1
      );
      await txApprove.wait();

      const nonceVault = uuidv4();
      const authVault = {
        signer: deployer,
        contract: vaultContract.address,
      };
      const typesVault = {
        ChargeTransferFeeStruct: [
          { name: "walletAddress", type: "address" },
          { name: "id", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "price", type: "uint256" },
          { name: "tokenAddress", type: "address" },
          { name: "itemAddress", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucherVault = {
        walletAddress: deployer.address,
        id: "123123",
        tokenId: "1",
        price: ethers.utils.parseEther("1"),
        tokenAddress: "0x0000000000000000000000000000000000000000",
        itemAddress: NFTContract.address,
        nonce: nonceVault,
      };

      const signatureVault = await createVoucher(
        typesVault,
        authVault,
        voucherVault,
        "Vault-Item",
        "1"
      );
      const txVault = await vaultContract
        .connect(deployer)
        .chargeFeeTransfer(signatureVault, {
          value: ethers.utils.parseEther("1"),
        });
      await txVault.wait();
    });
  });
  describe("Transfer, Cancel and Claim", async () => {
    it("Transfer and Cancel NFT to vault", async () => {
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
      const txApprove = await NFTContract.connect(deployer).approve(
        vaultContract.address,
        1
      );
      await txApprove.wait();

      const nonceVault = uuidv4();
      const authVault = {
        signer: deployer,
        contract: vaultContract.address,
      };
      const typesVault = {
        TransferNFTStruct: [
          { name: "id", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "price", type: "uint256" },
          { name: "fee", type: "uint256" },
          { name: "from", type: "address" },
          { name: "to", type: "address" },
          { name: "tokenAddress", type: "address" },
          { name: "nftAddress", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucherVault = {
        id: "123123",
        tokenId: "1",
        price: ethers.utils.parseEther("1"),
        fee: ethers.utils.parseEther("1"),
        from: deployer.address,
        to: user.address,
        tokenAddress: "0x0000000000000000000000000000000000000000",
        nftAddress: NFTContract.address,
        nonce: nonceVault,
      };

      const signatureVault = await createVoucher(
        typesVault,
        authVault,
        voucherVault,
        "Vault-Item",
        "1"
      );
      const txVault = await vaultContract
        .connect(deployer)
        .chargeFeeTransferNFT(signatureVault, {
          value: ethers.utils.parseEther("1"),
        });
      await txVault.wait();

      expect(
        await await NFTContract.connect(deployer).balanceOf(
          vaultContract.address
        )
      ).to.equal(1);

      const nonceCancel = uuidv4();
      const authCacel = {
        signer: deployer,
        contract: vaultContract.address,
      };
      const typesCancel = {
        CancelTransferNFTStruct: [
          { name: "id", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "owner", type: "address" },
          { name: "nftAddress", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucherCancel = {
        id: "123123",
        tokenId: "1",
        owner: deployer.address,
        nftAddress: NFTContract.address,
        nonce: nonceCancel,
      };

      const signatureCancel = await createVoucher(
        typesCancel,
        authCacel,
        voucherCancel,
        "Vault-Item",
        "1"
      );
      const txCancel = await vaultContract
        .connect(deployer)
        .cancelTransferNFT(signatureCancel);
      await txCancel.wait();
      expect(
        await await NFTContract.connect(deployer).balanceOf(deployer.address)
      ).to.equal(1);
    });

    it("Transfer and Claim NFT to vault", async () => {
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

      expect(
        await await NFTContract.connect(deployer).balanceOf(deployer.address)
      ).to.equal(1);

      await tx.wait();
      const txApprove = await NFTContract.connect(deployer).approve(
        vaultContract.address,
        1
      );
      await txApprove.wait();

      const nonceVault = uuidv4();
      const authVault = {
        signer: deployer,
        contract: vaultContract.address,
      };
      const typesVault = {
        TransferNFTStruct: [
          { name: "id", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "price", type: "uint256" },
          { name: "fee", type: "uint256" },
          { name: "from", type: "address" },
          { name: "to", type: "address" },
          { name: "tokenAddress", type: "address" },
          { name: "nftAddress", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucherVault = {
        id: "123123",
        tokenId: "1",
        price: ethers.utils.parseEther("1"),
        fee: ethers.utils.parseEther("1"),
        from: deployer.address,
        to: user.address,
        tokenAddress: "0x0000000000000000000000000000000000000000",
        nftAddress: NFTContract.address,
        nonce: nonceVault,
      };

      const signatureVault = await createVoucher(
        typesVault,
        authVault,
        voucherVault,
        "Vault-Item",
        "1"
      );
      const txVault = await vaultContract
        .connect(deployer)
        .chargeFeeTransferNFT(signatureVault, {
          value: ethers.utils.parseEther("1"),
        });
      await txVault.wait();

      expect(
        await await NFTContract.connect(deployer).balanceOf(
          vaultContract.address
        )
      ).to.equal(1);

      const nonceClaim = uuidv4();
      const authClaim = {
        signer: deployer,
        contract: vaultContract.address,
      };
      const typesClaim = {
        ClaimNFTStruct: [
          { name: "id", type: "string" },
          { name: "tokenId", type: "uint256" },
          { name: "price", type: "uint256" },
          { name: "fee", type: "uint256" },
          { name: "from", type: "address" },
          { name: "to", type: "address" },
          { name: "tokenAddress", type: "address" },
          { name: "nftAddress", type: "address" },
          { name: "nonce", type: "string" },
        ],
      };
      const voucherClaim = {
        id: "123123",
        tokenId: "1",
        price: ethers.utils.parseEther("1"),
        fee: ethers.utils.parseEther("1"),
        from: deployer.address,
        to: user.address,
        tokenAddress: "0x0000000000000000000000000000000000000000",
        nftAddress: NFTContract.address,
        nonce: nonceClaim,
      };

      const signatureCancel = await createVoucher(
        typesClaim,
        authClaim,
        voucherClaim,
        "Vault-Item",
        "1"
      );
      const txCancel = await vaultContract
        .connect(user)
        .chargeFeeClaimNFT(signatureCancel, {
          value: ethers.utils.parseEther("1"),
        });
      await txCancel.wait();
      expect(
        await await NFTContract.connect(user).balanceOf(user.address)
      ).to.equal(1);
    });
  });
});
