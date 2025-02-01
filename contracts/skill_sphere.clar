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

;; Staking configuration
(define-constant min-issuer-stake u1000000) ;; In microSTX

;; Data vars
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
        transferable: bool
    }
)

(define-map authorized-issuers 
    principal 
    {
        active: bool,
        staked-amount: uint
    }
)

(define-map endorsements
    { cert-id: uint, endorser: principal }
    { 
        comment: (string-ascii 256),
        timestamp: uint
    }
)

(define-data-var certification-nonce uint u0)

;; Private functions
(define-private (is-authorized-issuer (issuer principal))
    (match (get-authorized-issuer-info issuer)
        issuer-info (and 
            (get active issuer-info)
            (>= (get staked-amount issuer-info) min-issuer-stake)
        )
        false
    )
)

;; Public functions
(define-public (stake-and-activate-issuer (stake-amount uint))
    (let (
        (sender tx-sender)
        (current-stake (default-to u0 (get staked-amount (map-get? authorized-issuers sender))))
    )
        (try! (stx-transfer? stake-amount sender (as-contract tx-sender)))
        (ok (map-set authorized-issuers 
            sender
            {
                active: true,
                staked-amount: (+ current-stake stake-amount)
            }
        ))
    )
)

(define-public (unstake-issuer (amount uint))
    (let (
        (sender tx-sender)
        (issuer-info (unwrap! (get-authorized-issuer-info sender) err-not-found))
        (current-stake (get staked-amount issuer-info))
    )
        (asserts! (>= current-stake amount) err-insufficient-stake)
        (try! (as-contract (stx-transfer? amount (as-contract tx-sender) sender)))
        (ok (map-set authorized-issuers
            sender
            {
                active: (>= (- current-stake amount) min-issuer-stake),
                staked-amount: (- current-stake amount)
            }
        ))
    )
)

(define-public (issue-certification (recipient principal) 
                                (title (string-ascii 64))
                                (description (string-ascii 256))
                                (validity-period uint)
                                (transferable bool))
    (let (
        (issuer tx-sender)
        (cert-id (var-get certification-nonce))
        (issue-date block-height)
        (expiry-date (+ block-height validity-period))
    )
        (asserts! (is-authorized-issuer issuer) err-unauthorized)
        (var-set certification-nonce (+ cert-id u1))
        (ok (map-set certifications
            { cert-id: cert-id }
            {
                issuer: issuer,
                recipient: recipient,
                title: title,
                description: description,
                issue-date: issue-date,
                expiry-date: expiry-date,
                revoked: false,
                transferable: transferable
            }
        ))
    )
)

(define-public (transfer-certification (cert-id uint) (new-recipient principal))
    (let (
        (cert (unwrap! (get-certification cert-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get recipient cert)) err-unauthorized)
        (asserts! (get transferable cert) err-unauthorized)
        (asserts! (not (get revoked cert)) err-unauthorized)
        (ok (map-set certifications
            { cert-id: cert-id }
            (merge cert { recipient: new-recipient })
        ))
    )
)

(define-public (add-endorsement (cert-id uint) (comment (string-ascii 256)))
    (let (
        (cert (unwrap! (get-certification cert-id) err-not-found))
    )
        (ok (map-set endorsements
            { cert-id: cert-id, endorser: tx-sender }
            {
                comment: comment,
                timestamp: block-height
            }
        ))
    )
)

(define-public (revoke-certification (cert-id uint))
    (let (
        (cert (unwrap! (get-certification cert-id) err-not-found))
    )
        (asserts! (is-eq tx-sender (get issuer cert)) err-unauthorized)
        (ok (map-set certifications
            { cert-id: cert-id }
            (merge cert { revoked: true })
        ))
    )
)

;; Read only functions
(define-read-only (get-certification (cert-id uint))
    (ok (map-get? certifications { cert-id: cert-id }))
)

(define-read-only (get-authorized-issuer-info (issuer principal))
    (map-get? authorized-issuers issuer)
)

(define-read-only (is-certification-valid (cert-id uint))
    (let (
        (cert (unwrap! (map-get? certifications { cert-id: cert-id }) err-not-found))
    )
        (ok (and
            (not (get revoked cert))
            (<= block-height (get expiry-date cert))
        ))
    )
)

(define-read-only (get-endorsements (cert-id uint))
    (ok (map-get? endorsements { cert-id: cert-id, endorser: tx-sender }))
)
