import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const address = process.env.VICTIM_ADDRESS;
  if (!address) throw Error("You must setup the VICTIM_ADDRESS env variable");

  const CoinFlip = await ethers.getContractFactory('CoinFlip');
  const coinFlip = await CoinFlip.deploy(address);

  await coinFlip.deployed();

  console.log(`CoinFlip was deployed to ${coinFlip.address} with victim_address ${address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
