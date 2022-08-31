import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const address = process.env.VICTIM_ADDRESS;
  if (!address) throw Error("You must setup the VICTIM_ADDRESS env variable");

  const Telephone = await ethers.getContractFactory('Telephone');
  const telephone = await Telephone.deploy(address);

  await telephone.deployed();

  console.log(`Telephone was deployed to ${telephone.address} with victim_address ${address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
