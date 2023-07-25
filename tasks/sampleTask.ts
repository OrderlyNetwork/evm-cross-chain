import { task } from "hardhat/config";

task("sampleTask", "Sample task demonstrating how to use hardhat task", async (taskArgs, hre) => {
    console.log("This is a sample task");
    console.log("The task arguments are:")
    console.log(taskArgs);
    console.log("The hardhat runtime network is:")
    console.log(hre.network.name);
}).addParam("param", "The param description", "default value");