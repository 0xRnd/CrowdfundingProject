# Crowdfunding Study Project

This project is a study case for understanding and practicing Solidity development by implementing a decentralized crowdfunding platform. It uses the Foundry framework for smart contract testing and deployment. The purpose of the project is to learn and demonstrate the development of Solidity smart contracts, focusing on crowdfunding use cases such as campaign creation, contributions, refunds, and fund withdrawals.

## Features

1. **Campaign Creation**
   - Users can create campaigns by providing a name, funding goal, and deadline.
   - Each campaign is assigned a unique identifier.

2. **Contribute to Campaigns**
   - Contributors can fund a specific campaign by sending Ether.
   - Contributions are recorded and associated with each contributor.

3. **Refund Mechanism**
   - Contributors can request refunds if the campaign’s goal is not met before the deadline.

4. **Withdraw Funds**
   - Campaign creators can withdraw the funds if the funding goal is met and the deadline has passed.

## Prerequisites

- **Node.js**: Required to install Foundry dependencies.
- **Foundry**: Ensure Foundry is installed on your system. If not, follow the [Foundry installation guide](https://book.getfoundry.sh/getting-started/installation.html).
- **Solidity Knowledge**: Basic understanding of Solidity and Ethereum development.
- **Ethereum RPC URL**: Required for local simulations and testing.

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd crowdfunding-study-project
   ```

2. Install Foundry dependencies:
   ```bash
   forge install
   ```

3. Compile the smart contracts:
   ```bash
   forge build
   ```

## Project Structure

- **`src/Crowdfunding.sol`**: The main Solidity file containing the smart contract logic.
- **`test/CrowdfundingTest.t.sol`**: Test cases written in Solidity for verifying the contract functionality.
- **`script/CrowdfundingScript.s.sol`**: Script for deploying the smart contract.

## Usage

### Running Tests

Run all test cases to verify the contract:
```bash
forge test
```

Run a specific test:
```bash
forge test --match-test testRefundSuccess
```

### Simulate Local Deployment

Simulate deployment using a local Ethereum fork:
```bash
forge script script/CrowdfundingScript.s.sol:CrowdfundingScript --fork-url <RPC_URL>
```

### Deploy to Testnet

Deploy to a testnet (e.g., Goerli):
```bash
forge script script/CrowdfundingScript.s.sol:CrowdfundingScript --rpc-url <GOERLI_RPC_URL> --broadcast --private-key <PRIVATE_KEY>
```

## Smart Contract Functions

### `createCampaign(string memory name, uint goal, uint duration)`
- Creates a new crowdfunding campaign.
- Parameters:
  - `name`: Name of the campaign.
  - `goal`: Funding goal in Wei.
  - `duration`: Duration of the campaign in seconds.

### `contribute(uint campaignId)`
- Allows users to contribute to a specific campaign by sending Ether.

### `refund(uint campaignId)`
- Allows contributors to get a refund if the campaign’s goal is not met before the deadline.

### `withdrawFunds(uint campaignId)`
- Allows the campaign creator to withdraw funds if the goal is met and the deadline has passed.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- [Foundry Documentation](https://book.getfoundry.sh/)
- Ethereum and Solidity official documentation
- Community tutorials and resources on crowdfunding dApps

---

Feel free to use this project as a learning tool or template for your own decentralized applications! Contributions and suggestions are welcome.
