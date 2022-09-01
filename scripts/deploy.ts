import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const address = process.env.VICTIM_ADDRESS;
  if (!address) throw Error("You must setup the VICTIM_ADDRESS env variable");

  const contractName = process.argv[3];
  if (!contractName) throw Error("You must provide a contractName parameter (yarn deploy -- <contract_name>)");

  const Contract = await ethers.getContractFactory(contractName);
  const contract = await Contract.deploy(address);

  await contract.deployed();

  console.log(`${contractName} was deployed to ${contract.address} with victimAddress = ${address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
