;; SkillSphere Contract
(use-trait sip-009 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-expired (err u104))
(define-constant err-staking-required (err u105))
(define-constant err-insufficient-stake (err u106))
(define-constant err-cooldown-active (err u107))
(define-constant err-invalid-input (err u108))

;; Staking configuration
(define-constant min-issuer-stake u1000000) ;; In microSTX
(define-constant unstake-cooldown-blocks u144) ;; ~24 hours

;; Data vars
(define-data-var certification-nonce uint u0)

;; Enhanced data maps
(define-map certifications
    { cert-id: uint }
    {
        issuer: principal,
        recipient: principal,
        title: (string-ascii 64),
        description: (string-ascii 256),
        issue-date: uint,
        expiry-date: uint,
        revoked: bool,
        transferable: bool,
        metadata: (optional (string-ascii 512))
    }
)

(define-map authorized-issuers 
    principal 
    {
        active: bool,
        staked-amount: uint,
        reputation-score: uint,
        last-unstake-height: uint
    }
)

(define-map endorsements
    { cert-id: uint, endorser: principal }
    { 
        comment: (string-ascii 256),
        timestamp: uint,
        rating: uint
    }
)

;; Events
(define-data-var last-event-nonce uint u0)

(define-private (emit-event (event-type (string-ascii 32)) (data (string-ascii 256)))
    (let ((event-id (var-get last-event-nonce)))
        (var-set last-event-nonce (+ event-id u1))
        (print { event-id: event-id, type: event-type, data: data })
    )
)

;; Enhanced private functions
(define-private (is-authorized-issuer (issuer principal))
    (match (get-authorized-issuer-info issuer)
        issuer-info (and 
            (get active issuer-info)
            (>= (get staked-amount issuer-info) min-issuer-stake)
        )
        false
    )
)

(define-private (validate-string-length (str (string-ascii 256)))
    (< (len str) u256)
)

;; Enhanced public functions
(define-public (stake-and-activate-issuer (stake-amount uint))
    (let (
        (sender tx-sender)
        (current-stake (default-to u0 (get staked-amount (map-get? authorized-issuers sender))))
    )
        (asserts! (>= stake-amount min-issuer-stake) err-insufficient-stake)
        (try! (stx-transfer? stake-amount sender (as-contract tx-sender)))
        (emit-event "issuer-staked" (concat (to-ascii stake-amount) " STX staked by issuer"))
        (ok (map-set authorized-issuers 
            sender
            {
                active: true,
                staked-amount: (+ current-stake stake-amount),
                reputation-score: u100,
                last-unstake-height: u0
            }
        ))
    )
)

(define-public (unstake-issuer (amount uint))
    (let (
        (sender tx-sender)
        (issuer-info (unwrap! (get-authorized-issuer-info sender) err-not-found))
        (current-stake (get staked-amount issuer-info))
        (last-unstake (get last-unstake-height issuer-info))
    )
        (asserts! (>= current-stake amount) err-insufficient-stake)
        (asserts! (>= (- block-height last-unstake) unstake-cooldown-blocks) err-cooldown-active)
        (try! (as-contract (stx-transfer? amount (as-contract tx-sender) sender)))
        (emit-event "issuer-unstaked" (concat (to-ascii amount) " STX unstaked"))
        (ok (map-set authorized-issuers
            sender
            {
                active: (>= (- current-stake amount) min-issuer-stake),
                staked-amount: (- current-stake amount),
                reputation-score: (get reputation-score issuer-info),
                last-unstake-height: block-height
            }
        ))
    )
)

;; [Rest of the contract functions remain the same but with added event emissions
;; and enhanced error handling. Removing for brevity but would be included in full implementation]
