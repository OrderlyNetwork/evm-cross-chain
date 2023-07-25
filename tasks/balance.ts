import { task } from "hardhat/config";

task("balance", "Prints an account's balance", async (taskArgs, hre) => {
    // print ethers version
    console.log('ethers version: ', hre.ethers.version);
    const accounts = await hre.ethers.getSigners();
    for (const account of accounts) {
        const balance = await hre.ethers.provider.getBalance(account.address);
        console.log(`Account ${account.address} has a balance of: ${hre.ethers.formatEther(balance)} ETH`);
    }
});