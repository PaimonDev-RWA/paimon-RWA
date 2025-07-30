import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { SEPOLIA_CONFIG as config } from "../../config/sepolia-config";
import { BigNumber } from "@ethersproject/bignumber";
import * as dotenv from "dotenv";
dotenv.config();

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await main();

  async function main() {
    // await deployUSDC();
    // await deployRWAToken();
    // await deployRWAToken_SpaceX();
    // await deployRWAManager();
    // await deployRWAManager_SpaceX();
    // await setRWAToken();
    // await transferManagerOwner(config.deployedAddress.RWAManager, config.defaultAddress.test_owner);
    // await transferManagerOwner(config.deployedAddress.RWAToken, config.defaultAddress.test_owner);
    // await deploySubscription();
    // await deployRedemption();
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

  async function deployUSDC() {
    await deployContract("USDC", "USDCMock", [1_000_000_000_000000]);
  } 

  async function deployRWAToken() {
    await deployContract("RWAToken", "RWAToken", ["Paimon BCRED", "PAIBX"]);
  }

  async function deployRWAManager() {
    await deployContract("RWAManager", "RWAManager", [config.deployedAddress.RWAToken, config.deployedAddress.USDC]);
  }

  async function deployRWAToken_SpaceX() {
    await deployContract("RWAToken_SpaceX", "RWAToken", ["Paimon SpaceX SPV Token", "SPCX"]);
  }

  async function deployRWAManager_SpaceX() {
    await deployContract("RWAManager_SpaceX", "RWAManager", [config.deployedAddress.RWAToken_SpaceX, config.deployedAddress.USDC]);
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
      config.deployedAddress.RWAManager // Manager address
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
      config.deployedAddress.RWAManager // Manager address
    ];
    console.log(args)
    await deployContract("Redemption", "Redemption", args)
  }

  async function setRWAToken() {
    const rwaToken = await ethers.getContractAt("RWAToken", config.deployedAddress.RWAToken);
    console.log("set manager...")
    rwaToken.setManager(config.deployedAddress.RWAManager);
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
