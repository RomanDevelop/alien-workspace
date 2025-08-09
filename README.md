## ALIEN Token and Presale Contracts

This repository contains two main Solidity contracts and a few Remix example contracts/scripts. The two first‑class contracts are:

- `ALIEN_V2` — a managed, pausable, blacklist‑enabled ERC‑20‑like token
- `AlienPresale` — an ETH‑based token presale contract with claim flow

Solidity version: ^0.8.19

### Contents

- Overview
- Contracts
  - ALIEN_V2
  - AlienPresale
- How to deploy (Remix and Hardhat)
- How to run a presale
- Security notes and limitations
- Useful commands and artifacts

---

## Overview

The `ALIEN_V2` token is a simple ERC‑20‑like implementation that uses OpenZeppelin’s `Ownable`, `Pausable`, and `ReentrancyGuard`. It mints an initial fixed total supply to the `initialOwner` at deployment time and also supports owner‑controlled minting/burning, pausing, and address blacklisting.

The `AlienPresale` contract accepts ETH during a configured time window, tracks contributions, and lets buyers claim their purchased tokens after the sale ends. The presale owner can withdraw raised ETH and unsold tokens after completion.

Both contracts use OpenZeppelin v5‑style ownership constructor (`Ownable(initialOwner)` / `Ownable(msg.sender)`). Ensure you use `@openzeppelin/contracts` v5.x.

---

## Contracts

### ALIEN_V2 (ALIEN.sol)

**Purpose**: Managed fungible token with pause and blacklist controls.

**Inheritance**: `Ownable`, `Pausable`, `ReentrancyGuard` (from OpenZeppelin v5)

**Key token parameters**:

- `name`: "ALIEN Token"
- `symbol`: "ALIEN"
- `decimals`: 18
- `totalSupply`: 1,000,000,000 × 10^18 initially minted to `initialOwner`

**State**:

- `mapping(address => uint256) balanceOf`
- `mapping(address => mapping(address => uint256)) allowance`
- `mapping(address => bool) blacklist`

**Events**:

- `Transfer(address from, address to, uint256 value)`
- `Approval(address owner, address spender, uint256 value)`
- `TokensMinted(address to, uint256 amount)`
- `TokensBurned(address from, uint256 amount)`
- `AddressBlacklisted(address account, bool status)`

**Core functions**:

- ERC‑20‑like:
  - `transfer(address to, uint256 value)`
  - `approve(address spender, uint256 value)`
  - `transferFrom(address from, address to, uint256 value)`
- Owner‑only:
  - `mint(address to, uint256 amount)`
  - `burnFrom(address from, uint256 amount)`
- Public burn: `burn(uint256 amount)`
- Controls:
  - `pause()` / `unpause()` (owner)
  - `setBlacklist(address user, bool status)` (owner)
  - `batchSetBlacklist(address[] users, bool status)` (owner)
- View helpers:
  - `getBlacklistStatus(address user)`
  - `getContractInfo()` → `(name, symbol, decimals, totalSupply, paused, owner)`

**Notes**:

- This is a custom ERC‑20 implementation (not inheriting `ERC20`). There is no `increaseAllowance`/`decreaseAllowance` and no EIP‑2612 `permit`.
- Approve/allowance race conditions are possible; users should set allowance to 0 before setting a new non‑zero allowance.
- Strong centralization: the owner can mint arbitrarily, pause transfers, blacklist addresses, and burn from arbitrary accounts via `burnFrom`.

---

### AlienPresale (AlienPresale.sol)

**Purpose**: ETH‑based presale that lets buyers purchase tokens during a time window and claim after the sale ends.

**Inheritance**: `Ownable`, `Pausable`, `ReentrancyGuard` + uses `IERC20` token interface

**Constructor parameters**:

- `_token` (`address`): ERC‑20 token address (must be 18 decimals for the price formula below)
- `_startTime` (`uint256` unix): presale start (must be in the future)
- `_endTime` (`uint256` unix): presale end (must be after start)
- `_hardCap` (`uint256` wei): maximum total ETH to raise
- `_tokenPrice` (`uint256` wei): price per 1 token unit (18 decimals)

**State**:

- `IERC20 public token`
- `uint256 public startTime, endTime, hardCap, totalRaised, tokenPrice`
- `mapping(address => uint256) contributions`
- `mapping(address => uint256) claimableTokens`

**Events**:

- `TokensPurchased(address buyer, uint256 amountEth, uint256 tokens)`
- `TokensClaimed(address buyer, uint256 tokens)`
- `FundsWithdrawn(address owner, uint256 amountEth)`
- `UnsoldTokensWithdrawn(address owner, uint256 tokens)`
- `PresalePaused(address owner, bool status)`

**Modifiers**:

- `presaleActive` → enforces time window, pause state, and `totalRaised < hardCap`

**Core flow**:

- Buy: `buyTokens()` (payable, nonReentrant)
  - Requires `msg.value > 0` and respects `hardCap`
  - Token amount: `tokens = (msg.value * 1e18) / tokenPrice`
  - Accrues `contributions` and `claimableTokens`
- Claim: `claimTokens()` (after `endTime`)
  - Transfers `claimableTokens[msg.sender]` from this contract to buyer
  - Requires the presale contract to hold enough tokens
    (owner must fund the contract before claims)
- Owner withdrawals (after end):
  - `withdrawFunds()` → transfers raised ETH to owner
  - `withdrawUnsoldTokens()` → transfers remaining token balance to owner
- Controls:
  - `pausePresale(bool status)`
  - `updatePresaleTimes(uint256 newStart, uint256 newEnd)`
  - `updateHardCap(uint256 newHardCap)` (must exceed `totalRaised`)
  - `updateTokenPrice(uint256 newPrice)` (> 0)
- Views:
  - `getPresaleInfo()` → timings, caps, price, paused, and an `isActive` flag
  - `getUserInfo(address user)` → contribution and claimable amount
  - `getPresaleProgress()` → `totalRaised`, `hardCap`, `remaining`, `progressPercent`
- Fallbacks: `receive()` and `fallback()` both call `buyTokens()`

**Price formula**:

```
tokensToReceive = (msg.value * 10^18) / tokenPrice
```

Assumes token has 18 decimals.

---

## How to deploy

### Option A: Remix (fastest)

1. Open the repository in Remix or upload `ALIEN.sol` and `AlienPresale.sol`.
2. Install/OpenZeppelin in Remix (or use Remix’s compiler with the import resolver): the code imports `@openzeppelin/contracts` v5 APIs.
3. Compile with Solidity ^0.8.19.
4. Deploy `ALIEN_V2` with constructor: `initialOwner` (address that will hold the supply/own the token).
5. Deploy `AlienPresale` with:
   - `token` = deployed `ALIEN_V2` address
   - `startTime`, `endTime` (unix)
   - `hardCap` (wei)
   - `tokenPrice` (wei per 1 token)
6. Fund presale with tokens: from the token owner, transfer enough `ALIEN_V2` to the `AlienPresale` contract address to cover all claims.
7. Buyers call `buyTokens()` or send ETH directly to the presale address during the active window.
8. After `endTime`:
   - Buyers call `claimTokens()`
   - Owner calls `withdrawFunds()` and `withdrawUnsoldTokens()`

### Option B: Hardhat (recommended for automation)

This repo currently contains Remix‑oriented scripts. To deploy via Hardhat, set up a standard Hardhat project and install dependencies:

```
npm init -y
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox typescript ts-node
npm install @openzeppelin/contracts@^5 ethers
```

Initialize Hardhat and configure networks/keys. Create simple deployment scripts that:

- Deploy `ALIEN_V2(initialOwner)`
- Deploy `AlienPresale(token, startTime, endTime, hardCap, tokenPrice)`
- Transfer tokens from the token owner to the presale contract

Example deploy script structure (pseudocode):

```
const Token = await ethers.getContractFactory("ALIEN_V2");
const token = await Token.deploy(initialOwner);

const Presale = await ethers.getContractFactory("AlienPresale");
const presale = await Presale.deploy(token.address, startTime, endTime, hardCap, tokenPrice);

await token.connect(owner).mint(owner.address, extraSupplyIfNeeded);
await token.connect(owner).transfer(presale.address, tokensForSale);
```

Run with `npx hardhat run --network <network> scripts/deploy.ts`.

---

## How to run a presale

1. Choose times and pricing:
   - `startTime` and `endTime` (unix seconds)
   - `tokenPrice` in wei per token (18 decimals)
   - `hardCap` in wei
2. Deploy token and presale.
3. Fund presale with enough tokens to cover all claims.
4. Announce the sale address and parameters to buyers.
5. During the sale, monitor `totalRaised` and `getPresaleProgress()`.
6. After end:
   - Buyers call `claimTokens()`
   - Owner calls `withdrawFunds()`
   - Owner calls `withdrawUnsoldTokens()`

---

## Security notes and limitations

- Token centralization: owner can mint, burnFrom, pause, and blacklist. Communicate this clearly to users.
- Blacklisted addresses cannot transfer/receive or be approved.
- Approval race condition: recommend setting allowance to 0 before updating to a new non‑zero value.
- Presale relies on the owner pre‑funding tokens to the contract before claims start.
- `nonReentrant` is used on state‑changing functions that transfer value.

If you need a more trust‑minimized token, consider inheriting from OpenZeppelin `ERC20`/`ERC20Pausable` and removing blacklist/mint/burnFrom, or gate them behind timelocks/multisig.

---

## Useful

- Solidity: ^0.8.19
- OpenZeppelin: `@openzeppelin/contracts` v5.x
- Artifacts (if using Remix): see `artifacts/` folder for compiled ABIs/bytecode
- Example tests in `tests/` are for Remix templates (`Storage`, `Ballot`) and are not presale/token tests.

## License

MIT

# alien-workspace

# alien-workspace
