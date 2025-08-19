# On-chain Generative Art Contract 🎨

A fully on-chain **generative art NFT contract** built on [Stacks Clarity](https://docs.stacks.co/write-smart-contracts/clarity-overview).  
This contract algorithmically generates unique art pieces with traits, rarity, evolution, and breeding mechanics — all stored and managed on-chain.

---

## ✨ Features

- **NFT Minting**
  - Non-fungible tokens representing generative art.
  - Configurable mint price, max supply, and minting state.

- **On-chain Trait Generation**
  - Deterministic pseudo-random generation of traits:
    - Color palette (10 variants)
    - Pattern type (5 variants)
    - Complexity (8 levels)
    - Size (3 levels)
    - Style (6 variants)
    - Symmetry (bool)
    - Animation (bool)
  - Automatic rarity scoring system.

- **Metadata**
  - Name & description generation based on traits.
  - Extended metadata includes description, artist signature, parameters, and optional IPFS hash.

- **Evolution System**
  - Art pieces can evolve over time through interaction.
  - Owners can add evolution points and upgrade their art’s complexity.
  - Evolutions have limits based on rarity.

- **Breeding System**
  - Combine two art NFTs to create a new unique child.
  - Inherits blended traits from both parents.
  - Breeding history recorded on-chain.

- **Collections**
  - Support for collections with constraints (palette range, pattern range, etc.).
  - Auto-updates collection counts when new art is minted into them.

- **Market Data**
  - Records price history of secondary sales.

- **Algorithm Management**
  - Admin can create and register new art generation algorithms.

---

## 🛠 Contract Architecture

### Data Structures
- `generative-art`: Main NFT token.
- `art-properties`: Core traits of each piece.
- `art-metadata`: Extended descriptive metadata.
- `collections`: Collections with constraints and info.
- `rarity-traits`: Tracks frequency of trait values.
- `generation-algorithms`: Different art generation algorithms.
- `art-evolution`: Tracks evolution stages and history.
- `breeding-records`: Parent/child lineage and breeding history.
- `price-history`: Market activity for each piece.

### Key Variables
- `art-counter`: Total number of minted NFTs.
- `minting-active`: Enable/disable minting.
- `mint-price`: Price per mint (default 1 STX).
- `max-supply`: Maximum supply of NFTs.
- `generation-seed`: Seed for pseudo-random trait generation.

---

## 🚀 Public Functions

### Minting
- **`(generate-art recipient collection-id)`**
  - Mints a new art piece to a recipient.
  - Optional: Assign to a collection.

### Evolution
- **`(evolve-art token-id)`**
  - Evolves an owned NFT to the next stage (requires points + STX).
- **`(interact-with-art token-id)`**
  - Adds evolution points through owner interaction.

### Breeding
- **`(breed-art parent1 parent2 recipient)`**
  - Breeds two NFTs to produce a new child NFT.

### Administration
- **`(set-minting-state active)`** → Enable/disable minting.
- **`(set-mint-price new-price)`** → Set mint price.
- **`(update-generation-seed new-seed)`** → Update randomness seed.
- **`(create-algorithm name description parameters)`** → Register new generation algorithm.
