import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { ethers } from "hardhat";

async function feedContract(contract: Contract, account: SignerWithAddress) {
  return await account.sendTransaction({
    to: contract.address,
    value: ethers.utils.parseUnits("0.001","ether")
  });
}

async function main() {
  const [account] = await ethers.getSigners();
  console.log("Running with the account:", account.address);
  console.log("Account balance:", (await account.getBalance()).toString());

  const contractAddress = "0x8fa4EAA1215f56798Fb55467D4d015096d543aA8";
  const Force = await ethers.getContractFactory("Force");
  const contract = Force.attach(contractAddress);

  const tx = await feedContract(contract, account);
  console.log('waiting to end transaction...');
  await tx.wait();
  
  const balance = await contract.provider.getBalance(contract.address);
  console.log('contract has balance of: ', Number(balance));

  const result = await contract.takeMyMoney({ gasLimit: 10000000 });
  console.log('data:', result.data);
  console.log('guess result:', result);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});