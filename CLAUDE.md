# CLAUDE.md

Foundry project. Solidity `^0.8.30`, OpenZeppelin via `lib/`, remappings in `remappings.txt`.

Build: `forge build` · Test: `forge test` · Format: `forge fmt`

## Structure

A learning monorepo: each project is an independent, unrelated set of contracts living in its own folder under `src/`, `test/`, and `script/`. Projects never import each other.

```
src/<project>/Contract.sol
src/<project>/interfaces/IContract.sol
test/<project>/Contract.t.sol
script/<project>/Contract.s.sol
```

Every contract has a matching interface in its project's `interfaces/` folder and inherits from it. `lib/` holds git submodule dependencies. Starting a new project means creating `<project>/` under all three roots — nothing else.

## Documentation convention

Reference: `src/pool/Pool.sol`, `src/pool/interfaces/IPool.sol`.

- **Contract/interface header** — `/** @title ... @author ... */` block above the declaration.
- **Section banners** — group members under 80-column banners, e.g. `Constant`, `Immutable state`, `State variables`, `Structures`, `Constructor`, `Errors`, `Events`, `Getters`, `Internal helpers`, `Public API`:
  ```
  /*------------------------------------------------------------------------*/
  /* Public API */
  /*------------------------------------------------------------------------*/
  ```
- **Natspec on every declaration** — state vars, constructor, and functions. Terse phrasing (`@notice Base token`, `@param recipient Recipient`, `@return Shares`). Errors, events, structs, and the external surface are documented on the interface; the implementation uses `@inheritdoc I<Name>`. Internal/private helpers carry full natspec.
- **Inline step comments** — a single-line `/* ... */` above each logical step inside a function body, e.g. `/* Transfer tokens in from sender */`, `/* Emit deposited event */`.
