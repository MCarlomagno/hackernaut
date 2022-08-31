# Hackernaut
Set of smart contracts for hacking the OpenZeppelin [Ethernaut game](https://ethernaut.openzeppelin.com/)

### Getting Started

1- Create an [Alchemy](https://www.alchemy.com/) account.
2- Create a testing Rinkeby testnet account and feed it with some RinkebyETH using the [Alchemy Faucet](https://rinkebyfaucet.com/).
3- Create a `.env` file on the root folder containing the following variables

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