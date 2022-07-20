import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers, network } from "hardhat";
import { v4 as uuidv4 } from "uuid";
import deployRUNNOWUpgradeable from "../../scripts/coin/deployRUNNOW";
import deployVestingUpgradeable from "../../scripts/vesting/deployVesting";

let deployer: SignerWithAddress;
let user: SignerWithAddress;
let VestingContract: Contract;
let RUNNOWContract: Contract;
const seed = "30000000";
const privateRound = "40000000";
const publicRound = "30000000";
const advisor = "50000000";
const team = "200000000";
const marketing = "150000000";
const reward = "400000000";
const farm = "50000000";
const liquidity = "50000000";

describe("Vesting;", () => {
  beforeEach(async () => {
    [deployer] = await ethers.getSigners();
    RUNNOWContract = await deployRUNNOWUpgradeable(deployer);
    VestingContract = await deployVestingUpgradeable(deployer);
    await RUNNOWContract.connect(deployer).transferOwnership(
      VestingContract.address
    );
  });

  describe("Vessting contract", async () => {
    it("Set Runnow and distribute", async () => {
      await VestingContract.connect(deployer).setRunnow(RUNNOWContract.address);
      const distributeTime = Math.floor(new Date().getTime() / 1000);
      await VestingContract.connect(deployer).setDistributeTime(distributeTime);
      for (let i = 0; i <= 36; i++) {
        await VestingContract.connect(deployer).distribute();
        const nextTime = distributeTime + 86400 * 30 * (i + 1) + 1;
        await network.provider.send("evm_setNextBlockTimestamp", [nextTime]);
        await network.provider.send("evm_mine");
      }

      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0x1357ea29093b7bd4e557D0638F7f3113Dd4D504e"
        )
      ).to.equal(ethers.utils.parseEther(seed));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0xabD002429daf2A4c383C4491ab968d8Eaeb9AB83"
        )
      ).to.equal(ethers.utils.parseEther(privateRound));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0x924db5A9C038A70bD812E403ebc96DF6271e26ba"
        )
      ).to.equal(ethers.utils.parseEther(publicRound));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0x2A7A70bDADc13eD9c31069B47d3df46058bDC4f5"
        )
      ).to.equal(ethers.utils.parseEther(advisor));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0xab985ef330f7560B4045D4A1E19A206A36c7479b"
        )
      ).to.equal(ethers.utils.parseEther(team));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0xC08c4Fc41F6F63A47E63505f8492fFfD753A2304"
        )
      ).to.equal(ethers.utils.parseEther(marketing));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0x6456be06d125C0B7F661E6E09E695AF4d59D58D1"
        )
      ).to.equal(ethers.utils.parseEther(reward));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0xeFfe75B1574Bdd2FE0Bc955b57e4f82A2BAD6bF9"
        )
      ).to.equal(ethers.utils.parseEther(farm));
      expect(
        await RUNNOWContract.connect(deployer).balanceOf(
          "0x5bc128b3711d741A0DdedD519d55AA60E60f442c"
        )
      ).to.equal(ethers.utils.parseEther(liquidity));
    });
  });
});
