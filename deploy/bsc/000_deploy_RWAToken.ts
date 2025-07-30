import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BSC_CONFIG as config } from "../../config/bsc-config";
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
    // await deployRWAToken1();
    // await deployRWAToken2();
    // await deployRWAToken3();
    // await deployRWAToken4();
    // await deployRWAToken5();
    // await deployRWAToken6();
    // await deployRWAToken7();
    // await deployRWAToken8();
    // await deployRWAToken9();
    // await deployRWAToken10();
    // await deployRWAToken11();
    // await deployRWAToken12();
    // await deployRWAToken13();
    // await deployRWAManager1();
    // await deployRWAManager2();
    // await deployRWAManager3();
    // await deployRWAManager4();
    // await deployRWAManager5();
    // await deployRWAManager6();
    // await deployRWAManager7();
    // await deployRWAManager8();
    // await deployRWAManager9();
    // await deployRWAManager10();
    // await deployRWAManager11();
    // await deployRWAManager12();
    // await deployRWAManager13();
    // await setRWAToken(config.deployedAddress.RWAToken1, config.deployedAddress.RWAManager1);
    // await setRWAToken(config.deployedAddress.RWAToken2, config.deployedAddress.RWAManager2);
    // await setRWAToken(config.deployedAddress.RWAToken3, config.deployedAddress.RWAManager3);
    // await setRWAToken(config.deployedAddress.RWAToken4, config.deployedAddress.RWAManager4);
    // await setRWAToken(config.deployedAddress.RWAToken5, config.deployedAddress.RWAManager5);
    // await setRWAToken(config.deployedAddress.RWAToken6, config.deployedAddress.RWAManager6);
    // await setRWAToken(config.deployedAddress.RWAToken7, config.deployedAddress.RWAManager7);
    // await setRWAToken(config.deployedAddress.RWAToken8, config.deployedAddress.RWAManager8);
    // await setRWAToken(config.deployedAddress.RWAToken9, config.deployedAddress.RWAManager9);
    // await setRWAToken(config.deployedAddress.RWAToken10, config.deployedAddress.RWAManager10);
    // await setRWAToken(config.deployedAddress.RWAToken11, config.deployedAddress.RWAManager11);
    // await setRWAToken(config.deployedAddress.RWAToken12, config.deployedAddress.RWAManager12);
    // await setRWAToken(config.deployedAddress.RWAToken13, config.deployedAddress.RWAManager13);
    // await deploySubscription();
    // await deployRedemption();
    // await transferManagerOwner(config.deployedAddress.RWAManager1, "0xeee13739763a1b0f062846ef4a102886673c89bd");
    // await transferManagerOwner(config.deployedAddress.RWAManager2, "0xeee13739763a1b0f062846ef4a102886673c89bd");
    // await transferManagerOwner(config.deployedAddress.RWAManager3, "0xeee13739763a1b0f062846ef4a102886673c89bd");
    // await transferManagerOwner(config.deployedAddress.RWAManager5, "0xeee13739763a1b0f062846ef4a102886673c89bd");
    // await transferManagerOwner(config.deployedAddress.RWAManager7, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager8, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager9, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager10, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager11, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager12, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAManager13, config.defaultAddress.yulong);
    // await transferManagerOwner(config.deployedAddress.RWAToken1, config.defaultAddress.PAIMON_TEAM);
    // await transferManagerOwner(config.deployedAddress.RWAToken2, config.defaultAddress.PAIMON_TEAM);
    // await transferManagerOwner(config.deployedAddress.RWAToken7, config.defaultAddress.PAIMON_TEAM);
    // await transferManagerOwner(config.deployedAddress.RWAToken5, config.defaultAddress.test_team);
    // await transferManagerOwner(config.deployedAddress.RWAToken8, config.defaultAddress.PAIMON_TEAM);
    // await transferManagerOwner(config.deployedAddress.RWAToken9, config.defaultAddress.PAIMON_TEAM);
    // await transferManagerOwner(config.deployedAddress.RWAToken10, config.defaultAddress.PAIMON_TEAM);
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

  async function deployRWAToken1() {
    await deployContract("RWAToken1", "RWAToken", ["Paimon A320 Aircraft Leasing Fund", "PA320"]);
  }

  async function deployRWAToken2() {
    await deployContract("RWAToken2", "RWAToken", ["Paimon Blackstone Private Credit Fund", "PBCR"]);
  }

  async function deployRWAToken3() {
    await deployContract("RWAToken3", "RWAToken", ["paimontest", "paimontest"]);
  }

  async function deployRWAToken4() {
    await deployContract("RWAToken4", "RWAToken", ["Paimon High Yield Token", "HYD"]);
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

  async function deployRWAToken8() {
    await deployContract("RWAToken8", "RWAToken", ["xAI SPV Token", "XAI"]);
  }

  async function deployRWAToken9() {
    await deployContract("RWAToken9", "RWAToken", ["Stripe SPV Token", "STRP"]);
  }

  async function deployRWAToken10() {
    await deployContract("RWAToken10", "RWAToken", ["Cursor SPV Token", "CRSR"]);
  }

  async function deployRWAToken11() {
    await deployContract("RWAToken11", "RWAToken", ["paimontest3", "paimontest3"]);
  }

  async function deployRWAToken12() {
    await deployContract("RWAToken12", "RWAToken", ["paimontest4", "paimontest4"]);
  }

  async function deployRWAToken13() {
    await deployContract("RWAToken13", "RWAToken", ["paimontest5", "paimontest5"]);
  }

  async function deployRWAManager1() {
    await deployContract("RWAManager1", "RWAManager", [config.deployedAddress.RWAToken1, config.deployedAddress.USDC]);
  }

  async function deployRWAManager2() {
    await deployContract("RWAManager2", "RWAManager", [config.deployedAddress.RWAToken2, config.deployedAddress.USDC]);
  }

  async function deployRWAManager3() {
    await deployContract("RWAManager3", "RWAManager", [config.deployedAddress.RWAToken3, config.deployedAddress.USDC]);
  }

  async function deployRWAManager4() {
    await deployContract("RWAManager4", "RWAManager", [config.deployedAddress.RWAToken4, config.deployedAddress.USDC]);
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

  async function deployRWAManager8() {
    await deployContract("RWAManager8", "RWAManager", [config.deployedAddress.RWAToken8, config.deployedAddress.USDC]);
  }

  async function deployRWAManager9() {
    await deployContract("RWAManager9", "RWAManager", [config.deployedAddress.RWAToken9, config.deployedAddress.USDC]);
  }

  async function deployRWAManager10() {
    await deployContract("RWAManager10", "RWAManager", [config.deployedAddress.RWAToken10, config.deployedAddress.USDC]);
  }

  async function deployRWAManager11() {
    await deployContract("RWAManager11", "RWAManager", [config.deployedAddress.RWAToken11, config.deployedAddress.USDC]);
  }

  async function deployRWAManager12() {
    await deployContract("RWAManager12", "RWAManager", [config.deployedAddress.RWAToken12, config.deployedAddress.USDC]);
  }

  async function deployRWAManager13() {
    await deployContract("RWAManager13", "RWAManager", [config.deployedAddress.RWAToken13, config.deployedAddress.USDC]);
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
