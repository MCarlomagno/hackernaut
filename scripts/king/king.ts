import { ethers } from "hardhat";

async function main() {
  const [account] = await ethers.getSigners();
  console.log("Running with the account:", account.address);
  console.log("Account balance:", (await account.getBalance()).toString());

  const contractAddress = "0x2dAb4C519018E022238869c244525767b182174d";
  const King = await ethers.getContractFactory("King");
  const contract = King.attach(contractAddress);

  const balance = await contract.provider.getBalance(contract.address);
  console.log('contract has balance of: ', Number(balance));

  const value = 1000000000000001;
  const result = await contract.becomeKing({ value });
  console.log('data:', result.data);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});