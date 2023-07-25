import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {DeployFunction} from 'hardhat-deploy/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const lockedAmount = hre.ethers.parseEther('0.0001');
  const deployer = (await hre.ethers.getSigners())[0];

  const Lock = await hre.ethers.getContractFactory("Lock");
  const lock = await Lock.deploy();
  const lock2 = await lock.waitForDeployment();
  hre.deployments.save('Lock', (await hre.deployments.getDeploymentsFromAddress(lock.target))[0]);
  //const lock = await hre.deployments.deploy('Lock', {
  //  from: deployer.address, 
  //})

  console.log(
    `Lock with ${hre.ethers.formatEther(
      lockedAmount
    )}ETH and unlock timestamp ${unlockTime} deployed to ${lock.target}`
  );
};
export default func;
func.tags = ['Lock'];