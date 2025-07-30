import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { HASHKEY_CONFIG as config } from "../../config/hashkey-config";
import { BigNumber } from "@ethersproject/bignumber";
import * as dotenv from "dotenv";
dotenv.config();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await main();

  async function main() {
    // await deployRWAToken5();
    // await deployRWAToken6();
    // await deployRWAToken7();
    // await deployRWAManager5();
    // await deployRWAManager6();
    // await deployRWAManager7();
    // await setRWAToken(config.deployedAddress.RWAToken5, config.deployedAddress.RWAManager5);
    // await setRWAToken(config.deployedAddress.RWAToken6, config.deployedAddress.RWAManager6);
    // await setRWAToken(config.deployedAddress.RWAToken7, config.deployedAddress.RWAManager7);
    // await transferManagerOwner(config.deployedAddress.RWAManager, config.defaultAddress.test_owner);
    // await transferManagerOwner(config.deployedAddress.RWAToken, config.defaultAddress.test_owner);
    // await deploySubscription();
    // await deployRedemption();
    // await transferManagerOwner(config.deployedAddress.RWAManager5, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager6, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager7, config.defaultAddress.yulong);
  }

  async function deployContract(name: string, contract: string, args?: any[]) {
    if (typeof args == "undefined") {
      args = [];
    }
    if (!config.deployedAddress[name] || config.deployedAddress[name] == "") {
      console.log("Deploying contract:", name);
      const deployResult = await deploy(contract, {
        from: deployer,
        args: args,
        log: true,
      });
      await verifyContract(deployResult.address, args);
      return deployResult.address;
    } else {
      console.log("Fetch previous deployed address for", name, config.deployedAddress[name]);
      return config.deployedAddress[name];
    }
  }

  async function verifyContract(address: string, args?: any[]) {
    if (typeof args == "undefined") {
      args = [];
    }
    try {
      await hre.run("verify:verify", {
        address: address,
        constructorArguments: args,
      });
    } catch (e) {
      if (e.message != "Contract source code already verified") {
        throw e;
      }
      console.log(e.message);
    }
  }

  async function deployRWAToken() {
    await deployContract("RWAToken", "RWAToken", ["Paimon BCRED", "PAIBX"]);
  }

  async function deployRWAToken5() {
    await deployContract("RWAToken5", "RWAToken", ["paimontest1", "paimontest1"]);
  }

  async function deployRWAToken6() {
    await deployContract("RWAToken6", "RWAToken", ["paimontest2", "paimontest2"]);
  }

  async function deployRWAToken7() {
    await deployContract("RWAToken7", "RWAToken", ["Paimon SpaceX SPV Token", "SPCX"]);
  }

  async function deployRWAManager5() {
    await deployContract("RWAManager5", "RWAManager", [config.deployedAddress.RWAToken5, config.deployedAddress.USDC]);
  }

  async function deployRWAManager6() {
    await deployContract("RWAManager6", "RWAManager", [config.deployedAddress.RWAToken6, config.deployedAddress.USDC]);
  }

  async function deployRWAManager7() {
    await deployContract("RWAManager7", "RWAManager", [config.deployedAddress.RWAToken7, config.deployedAddress.USDC]);
  }

  async function deploySubscription() {
    const subscriptionTotalCap = 1000000000
    const subscriptionUserCap = 1000000
    const currentTime = Math.floor(Date.now() / 1000);
    const args = [
      currentTime + 86400, // Start time: now + 1 day
      currentTime + (86400 * 30), // End time: now + 30 days
      subscriptionTotalCap,
      subscriptionUserCap,
      deployer, // Owner address
      config.deployedAddress.RWAManager5 // Manager address
    ];
    console.log(args)
    await deployContract("Subscription", "Subscription", args)
  }

  async function deployRedemption() {
    const redemptionTotalCap = 1000000000
    const redemptionUserCap = 1000000
    const currentTime = Math.floor(Date.now() / 1000);
    const args = [
      currentTime + 86400, // Start time: now + 1 day
      currentTime + (86400 * 30), // End time: now + 30 days
      redemptionTotalCap,
      redemptionUserCap,
      deployer, // Owner address
      config.deployedAddress.RWAManager5 // Manager address
    ];
    console.log(args)
    await deployContract("Redemption", "Redemption", args)
  }

  async function setRWAToken(token: string, manager: string) {
    const rwaToken = await ethers.getContractAt("RWAToken", token);
    console.log(`set manager for ${token}...`)
    const tx = await rwaToken.setManager(manager);
    const result = await tx.wait();
    logTranscation(result);
  }

  async function transferManagerOwner(managerAddress: string, owner: string) {
    const manager = await ethers.getContractAt("RWAManager", managerAddress)
    console.log(`transfer owner for ${managerAddress}...`)
    console.log(`transfer owner to ${owner}...`)
    const tx = await manager.transferOwnership(owner)
    const result = await tx.wait();
    logTranscation(result);
  }

  function logTranscation(result: any) {
    console.log("Transcation result:", result.transactionHash)
    console.log(`${config.chain.explorerURL}/tx/${result.transactionHash}`)
    console.log()
  }
};

export default func;
