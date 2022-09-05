import { ethers } from "hardhat";

async function main() {
  const [account] = await ethers.getSigners();
  console.log("Running with the account:", account.address);
  console.log("Account balance:", (await account.getBalance()).toString());

  const contractAddress = "0x58B21CaA365619ea56f67Fa569F0344Ad48556FB";
  const Reentrancy = await ethers.getContractFactory("Reentrancy");
  const contract = Reentrancy.attach(contractAddress);

  // TODO: show up the hacking process.
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});