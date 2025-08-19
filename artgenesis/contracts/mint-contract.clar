;; On-chain Generative Art Contract
;; Algorithmically generated art with unique properties

;; Define the generative art NFT
(define-non-fungible-token generative-art uint)

;; Data variables
(define-data-var art-counter uint u0)
(define-data-var contract-owner principal tx-sender)
(define-data-var minting-active bool true)
(define-data-var mint-price uint u1000000) ;; 1 STX
(define-data-var max-supply uint u10000)
(define-data-var generation-seed uint u42)

;; Art properties and metadata
(define-map art-properties
  { token-id: uint }
  {
    seed: uint,
    color-palette: uint, ;; 0-9 (10 different palettes)
    pattern-type: uint,  ;; 0-4 (5 different patterns)
    complexity: uint,    ;; 0-7 (8 complexity levels)
    size: uint,          ;; 0-2 (small, medium, large)
    style: uint,         ;; 0-5 (6 different artistic styles)
    symmetry: bool,      ;; symmetric or asymmetric
    animation: bool,     ;; static or animated
    generated-at: uint,
    generator-version: uint,
    rarity-score: uint
  }
)

;; Extended metadata
(define-map art-metadata
  { token-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    artist-signature: (string-ascii 32),
    creation-parameters: (string-ascii 512),
    ipfs-hash: (optional (string-ascii 64))
  }
)

;; Collection information
(define-map collections
  { collection-id: uint }
  {
    name: (string-ascii 64),
    description: (string-ascii 256),
    creator: principal,
    max-pieces: uint,
    current-count: uint,
    base-parameters: {
      palette-range: { min: uint, max: uint },
      pattern-range: { min: uint, max: uint },
      complexity-range: { min: uint, max: uint }
    },
    is-active: bool,
    created-at: uint
  }
)

(define-data-var collection-counter uint u0)

;; Rarity system
(define-map rarity-traits
  { trait-type: (string-ascii 32), trait-value: uint }
  {
    rarity-weight: uint,
    total-count: uint
  }
)

;; Generation algorithms
(define-map generation-algorithms
  { algorithm-id: uint }
  {
    name: (string-ascii 32),
    description: (string-ascii 128),
    version: uint,
    parameters: (string-ascii 256),
    is-active: bool,
    created-by: principal
  }
)

(define-data-var algorithm-counter uint u0)

;; Art evolution system
(define-map art-evolution
  { token-id: uint }
  {
    evolution-stage: uint,
    evolution-points: uint,
    last-evolution: uint,
    max-evolutions: uint,
    evolution-history: (list 10 uint) ;; Block heights of evolutions
  }
)

;; Breeding system for combining art pieces
(define-map breeding-records
  { parent1: uint, parent2: uint }
  {
    child: uint,
    bred-at: uint,
    breeder: principal,
    breeding-cost: uint
  }
)

;; Market data
(define-map price-history
  { token-id: uint, sale-id: uint }
  {
    price: uint,
    seller: principal,
    buyer: principal,
    sold-at: uint
  }
)

(define-data-var sale-id-counter uint u0)

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-FOUND (err u404))
(define-constant ERR-MINTING-INACTIVE (err u403))
(define-constant ERR-MAX-SUPPLY-REACHED (err u405))
(define-constant ERR-INSUFFICIENT-PAYMENT (err u402))
(define-constant ERR-INVALID-PARAMETERS (err u400))
(define-constant ERR-EVOLUTION-LIMIT (err u406))
(define-constant ERR-BREEDING-COOLDOWN (err u407))

;; Helper function for minimum value
(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b)
)

;; Administrative functions
(define-public (set-minting-state (active bool))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set minting-active active)
    (ok active)
  )
)

(define-public (set-mint-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set mint-price new-price)
    (ok new-price)
  )
)

(define-public (update-generation-seed (new-seed uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set generation-seed new-seed)
    (ok new-seed)
  )
)

;; Create generation algorithm
(define-public (create-algorithm 
    (name (string-ascii 32)) 
    (description (string-ascii 128)) 
    (parameters (string-ascii 256)))
  (let ((algorithm-id (+ (var-get algorithm-counter) u1)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    
    (map-set generation-algorithms
      { algorithm-id: algorithm-id }
      {
        name: name,
        description: description,
        version: u1,
        parameters: parameters,
        is-active: true,
        created-by: tx-sender
      }
    )
    
    (var-set algorithm-counter algorithm-id)
    (ok algorithm-id)
  )
)

;; Generate art piece
(define-public (generate-art (recipient principal) (collection-id (optional uint)))
  (let (
    (token-id (+ (var-get art-counter) u1))
    (base-random (+ (var-get generation-seed) (* token-id u37) block-height))
    (pseudo-random (mod base-random u1000000))
    (payment-amount (var-get mint-price))
  )
    (asserts! (var-get minting-active) ERR-MINTING-INACTIVE)
    (asserts! (<= token-id (var-get max-supply)) ERR-MAX-SUPPLY-REACHED)
    
    ;; Handle payment
    (if (> payment-amount u0)
      (try! (stx-transfer? payment-amount tx-sender (var-get contract-owner)))
      true
    )
    
    ;; Mint NFT
    (try! (nft-mint? generative-art token-id recipient))
    
    ;; Generate properties based on pseudo-random number
    (let (
      (color-palette (mod pseudo-random u10))
      (pattern-type (mod (/ pseudo-random u10) u5))
      (complexity (mod (/ pseudo-random u50) u8))
      (size (mod (/ pseudo-random u400) u3))
      (style (mod (/ pseudo-random u1200) u6))
      (symmetry (> (mod (/ pseudo-random u7200) u2) u0))
      (animation (> (mod (/ pseudo-random u14400) u4) u2)) ;; 25% chance
      (rarity-score (calculate-rarity-score color-palette pattern-type complexity size style symmetry animation))
    )
      ;; Store properties
      (map-set art-properties
        { token-id: token-id }
        {
          seed: pseudo-random,
          color-palette: color-palette,
          pattern-type: pattern-type,
          complexity: complexity,
          size: size,
          style: style,
          symmetry: symmetry,
          animation: animation,
          generated-at: block-height,
          generator-version: u1,
          rarity-score: rarity-score
        }
      )
      
      ;; Initialize evolution data
      (map-set art-evolution
        { token-id: token-id }
        {
          evolution-stage: u0,
          evolution-points: u0,
          last-evolution: u0,
          max-evolutions: (+ u3 (mod rarity-score u5)), ;; 3-7 max evolutions based on rarity
          evolution-history: (list)
        }
      )
      
      ;; Generate name and description
      (let (
        (generated-name (generate-art-name pattern-type style complexity))
        (generated-description (generate-art-description color-palette symmetry animation))
      )
        (map-set art-metadata
          { token-id: token-id }
          {
            name: generated-name,
            description: generated-description,
            artist-signature: "GenArt AI v1.0",
            creation-parameters: (generate-parameter-string pseudo-random),
            ipfs-hash: none
          }
        )
      )
      
      ;; Update collection if specified
      (match collection-id
        coll-id (update-collection-count coll-id)
        true
      )
      
      ;; Update trait rarities
      (update-trait-rarity "color-palette" color-palette)
      (update-trait-rarity "pattern-type" pattern-type)
      (update-trait-rarity "complexity" complexity)
      
      (var-set art-counter token-id)
      (ok token-id)
    )
  )
)

;; Calculate rarity score based on traits
(define-private (calculate-rarity-score (palette uint) (pattern uint) (complexity uint) (size uint) (style uint) (symmetry bool) (animation bool))
  (let (
    (base-score (+ palette (* pattern u10) (* complexity u100)))
    (size-bonus (* size u50))
    (style-bonus (* style u20))
    (symmetry-bonus (if symmetry u100 u0))
    (animation-bonus (if animation u500 u0)) ;; Rare trait
  )
    (+ base-score size-bonus style-bonus symmetry-bonus animation-bonus)
  )
)

;; Generate art name based on properties
(define-private (generate-art-name (pattern uint) (style uint) (complexity uint))
  (if (is-eq pattern u0)
    (if (< complexity u4) "Gentle Waves" "Turbulent Seas")
    (if (is-eq pattern u1)
      (if (< style u3) "Geometric Dreams" "Crystal Lattice")
      (if (is-eq pattern u2)
        "Fractal Harmony"
        (if (is-eq pattern u3)
          "Abstract Emotion"
          "Digital Synthesis"
        )
      )
    )
  )
)

;; Generate art description
(define-private (generate-art-description (palette uint) (symmetry bool) (animation bool))
  (if animation
    "A dynamic piece that evolves with time, capturing the essence of digital motion."
    (if symmetry
      "Perfect balance achieved through algorithmic precision and artistic vision."
      "Asymmetric beauty born from controlled chaos and computational creativity."
    )
  )
)

;; Generate parameter string for metadata
(define-private (generate-parameter-string (seed uint))
  (concat 
    "seed:" 
    (concat 
      (uint-to-ascii seed) 
      "|algo:v1|chain:stacks"
    )
  )
)

;; Evolution system
(define-public (evolve-art (token-id uint))
  (let (
    (owner (unwrap! (nft-get-owner? generative-art token-id) ERR-NOT-FOUND))
    (evolution-data (unwrap! (map-get? art-evolution { token-id: token-id }) ERR-NOT-FOUND))
    (properties (unwrap! (map-get? art-properties { token-id: token-id }) ERR-NOT-FOUND))
    (evolution-cost u500000) ;; 0.5 STX
  )
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    (asserts! (< (get evolution-stage evolution-data) (get max-evolutions evolution-data)) ERR-EVOLUTION-LIMIT)
    (asserts! (>= (get evolution-points evolution-data) u100) ERR-INSUFFICIENT-PAYMENT)
    
    ;; Pay evolution cost
    (try! (stx-transfer? evolution-cost tx-sender (var-get contract-owner)))
    
    ;; Update evolution data
    (let (
      (new-stage (+ (get evolution-stage evolution-data) u1))
      (new-history (unwrap! (as-max-len? 
        (append (get evolution-history evolution-data) block-height) u10) ERR-INVALID-PARAMETERS))
    )
      (map-set art-evolution
        { token-id: token-id }
        {
          evolution-stage: new-stage,
          evolution-points: u0,
          last-evolution: block-height,
          max-evolutions: (get max-evolutions evolution-data),
          evolution-history: new-history
        }
      )
      
      ;; Update properties with evolution
      (map-set art-properties
        { token-id: token-id }
        (merge properties {
          complexity: (min-uint (+ (get complexity properties) u1) u7),
          rarity-score: (+ (get rarity-score properties) u100)
        })
      )
      
      (ok new-stage)
    )
  )
)

;; Add evolution points through interaction
(define-public (interact-with-art (token-id uint))
  (let (
    (owner (unwrap! (nft-get-owner? generative-art token-id) ERR-NOT-FOUND))
    (evolution-data (unwrap! (map-get? art-evolution { token-id: token-id }) ERR-NOT-FOUND))
    (time-since-last (- block-height (get last-evolution evolution-data)))
    (points-gained (if (> time-since-last u144) u10 u1)) ;; More points if longer time
  )
    (asserts! (is-eq tx-sender owner) ERR-NOT-AUTHORIZED)
    
    (map-set art-evolution
      { token-id: token-id }
      (merge evolution-data {
        evolution-points: (+ (get evolution-points evolution-data) points-gained)
      })
    )
    
    (ok points-gained)
  )
)

;; Breeding system
(define-public (breed-art (parent1 uint) (parent2 uint) (recipient principal))
  (let (
    (owner1 (unwrap! (nft-get-owner? generative-art parent1) ERR-NOT-FOUND))
    (owner2 (unwrap! (nft-get-owner? generative-art parent2) ERR-NOT-FOUND))
    (props1 (unwrap! (map-get? art-properties { token-id: parent1 }) ERR-NOT-FOUND))
    (props2 (unwrap! (map-get? art-properties { token-id: parent2 }) ERR-NOT-FOUND))
    (breeding-cost u2000000) ;; 2 STX
    (child-id (+ (var-get art-counter) u1))
  )
    (asserts! (or (is-eq tx-sender owner1) (is-eq tx-sender owner2)) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq parent1 parent2)) ERR-INVALID-PARAMETERS)
    
    ;; Pay breeding cost
    (try! (stx-transfer? breeding-cost tx-sender (var-get contract-owner)))
    
    ;; Check breeding history to prevent immediate re-breeding
    (asserts! (is-none (map-get? breeding-records { parent1: parent1, parent2: parent2 })) ERR-BREEDING-COOLDOWN)
    (asserts! (is-none (map-get? breeding-records { parent1: parent2, parent2: parent1 })) ERR-BREEDING-COOLDOWN)
    
    ;; Mint child NFT
    (try! (nft-mint? generative-art child-id recipient))
    
    ;; Combine properties from parents
    (let (
      (child-seed (+ (get seed props1) (get seed props2)))
      (child-palette (mod (+ (get color-palette props1) (get color-palette props2)) u10))
      (child-pattern (mod (+ (get pattern-type props1) (get pattern-type props2)) u5))
      (child-complexity (min-uint (+ (get complexity props1) (get complexity props2)) u7))
      (child-size (mod (+ (get size props1) (get size props2)) u3))
      (child-style (mod (+ (get style props1) (get style props2)) u6))
      (child-symmetry (or (get symmetry props1) (get symmetry props2)))
      (child-animation (and (get animation props1) (get animation props2)))
    )
      ;; Store child properties
      (map-set art-properties
        { token-id: child-id }
        {
          seed: child-seed,
          color-palette: child-palette,
          pattern-type: child-pattern,
          complexity: child-complexity,
          size: child-size,
          style: child-style,
          symmetry: child-symmetry,
          animation: child-animation,
          generated-at: block-height,
          generator-version: u2, ;; Bred version
          rarity-score: (calculate-rarity-score child-palette child-pattern child-complexity child-size child-style child-symmetry child-animation)
        }
      )
      
      ;; Record breeding
      (map-set breeding-records
        { parent1: parent1, parent2: parent2 }
        {
          child: child-id,
          bred-at: block-height,
          breeder: tx-sender,
          breeding-cost: breeding-cost
        }
      )
      
      (var-set art-counter child-id)
      (ok child-id)
    )
  )
)

;; Helper functions
(define-private (update-trait-rarity (trait-type (string-ascii 32)) (trait-value uint))
  (let (
    (current-data (default-to { rarity-weight: u100, total-count: u0 }
      (map-get? rarity-traits { trait-type: trait-type, trait-value: trait-value })
    ))
  )
    (map-set rarity-traits
      { trait-type: trait-type, trait-value: trait-value }
      {
        rarity-weight: (get rarity-weight current-data),
        total-count: (+ (get total-count current-data) u1)
      }
    )
  )
)

(define-private (update-collection-count (collection-id uint))
  (let ((collection (map-get? collections { collection-id: collection-id })))
    (match collection
      coll (map-set collections
        { collection-id: collection-id }
        (merge coll { current-count: (+ (get current-count coll) u1) })
      )
      false
    )
  )
)

(define-private (uint-to-ascii (num uint))
  "0" ;; Simplified - in practice would convert uint to string
)

;; Read-only functions
(define-read-only (get-art-properties (token-id uint))
  (map-get? art-properties { token-id: token-id })
)

(define-read-only (get-art-metadata (token-id uint))
  (map-get? art-metadata { token-id: token-id })
)

(define-read-only (get-evolution-data (token-id uint))
  (map-get? art-evolution { token-id: token-id })
)

(define-read-only (get-rarity-score (token-id uint))
  (match (get-art-properties token-id)
    props (ok (get rarity-score props))
    ERR-NOT-FOUND
  )
)

(define-read-only (get-breeding-record (parent1 uint) (parent2 uint))
  (map-get? breeding-records { parent1: parent1, parent2: parent2 })
)

(define-read-only (get-contract-info)
  {
    total-generated: (var-get art-counter),
    max-supply: (var-get max-supply),
    mint-price: (var-get mint-price),
    minting-active: (var-get minting-active),
    owner: (var-get contract-owner)
  }
)