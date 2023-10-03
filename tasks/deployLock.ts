import { task } from "hardhat/config";

task("deployLock", "deploy lock using task", async (taskArgs, hre) => {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const lockedAmount = hre.ethers.parseEther("0.0000000001");

  //const Lock = await hre.ethers.getContractFactory("Lock");
  //const lock = await Lock.deploy(unlockTime, { value: lockedAmount });
  //await lock.waitForDeployment();
  const deployer = (await hre.ethers.getSigners())[0];

  const lock = await hre.deployments.deploy('Lock', {
    from: deployer.address,
    args: [],
    deterministicDeployment: "0x11111",
  });
    

  console.log(
    `Lock with ${hre.ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.address}`
  );
});