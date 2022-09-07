

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract } from "ethers";
import { ethers } from "hardhat";

// type defined for CLI arguments
type Params = [level: string, victim: string, attacker: string];

function getParams(args: string[]) : Params {
  const params: Params = ['','',''];
  args.forEach(arg => {
    const [key, value] = arg.split('=');
    switch (key) {
      case 'level': params[0] = value;
      case 'victim': params[1] = value;
      case 'attacker': params[2] = value;
    }
  });
  return params;
}

async function feedContract(contract: Contract, account: SignerWithAddress) {
  await account.sendTransaction({
    to: contract.address,
    value: ethers.utils.parseUnits("0.001","ether")
  }).then(tx => tx.wait());
}

async function main() {
  const [level, victim, attacker] = getParams(process.argv);

  const [account] = await ethers.getSigners();
  console.log(
    "Running with the account:",
    account.address,
    "with balance:",
    (await account.getBalance()).toString()
  );

  const Level = await ethers.getContractFactory(level);
  const attackerContract = Level.attach(attacker);

  console.log('feeding attacker contract..');
  await feedContract(attackerContract, account);

  const balance = await attackerContract.provider.getBalance(attackerContract.address);
  console.log('attacker contract has balance of: ', Number(balance));
  
  const result = await attackerContract.hack();
  console.log('data:', result.data);
  console.log('guess result:', result);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});