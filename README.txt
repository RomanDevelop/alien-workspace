ALIEN Token and Presale — Quick Reference

This workspace contains the primary contracts for an ALIEN token and its ETH presale, as well as default Remix examples.

Primary contracts
- ALIEN.sol → ALIEN_V2: managed ERC‑20‑like token with pause and blacklist
  - name: ALIEN Token, symbol: ALIEN, decimals: 18
  - initial total supply: 1,000,000,000 × 10^18 assigned to initialOwner
  - owner controls: mint, burnFrom, pause/unpause, blacklist
- AlienPresale.sol → AlienPresale: ETH presale with post‑sale claiming
  - parameters: token, startTime, endTime, hardCap (wei), tokenPrice (wei per token)
  - buyers send ETH during [start, end] and claim tokens after end
  - owner can withdraw raised ETH and unsold tokens after end

Dependencies
- Solidity ^0.8.19
- OpenZeppelin contracts v5.x (`Ownable`, `Pausable`, `ReentrancyGuard`, `IERC20`)

Presale flow
1) Deploy ALIEN_V2(initialOwner)
2) Deploy AlienPresale(token, startTime, endTime, hardCap, tokenPrice)
3) Fund presale with enough ALIEN tokens (transfer to the presale contract)
4) Buyers call buyTokens() or send ETH directly to the presale address
5) After endTime: buyers claimTokens(); owner withdraws funds and unsold tokens

Remix scripts (optional)
- scripts/deploy_with_ethers.ts and scripts/deploy_with_web3.ts are Remix‑oriented and use Remix globals.

Notes
- Token is centralized (owner can mint/burnFrom/pause/blacklist)
- Approve/allowance race condition applies; recommend setting allowance to 0 before updating to a new non‑zero value
- Presale requires the owner to pre‑fund the contract with tokens before claims