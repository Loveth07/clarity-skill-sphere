;; SkillSphere Contract
(use-trait sip-009 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-expired (err u104))

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
        revoked: bool
    }
)

(define-map authorized-issuers principal bool)

(define-map endorsements
    { cert-id: uint, endorser: principal }
    { 
        comment: (string-ascii 256),
        timestamp: uint
    }
)

;; Data vars
(define-data-var certification-nonce uint u0)

;; Private functions
(define-private (is-authorized-issuer (issuer principal))
    (default-to false (get-authorized-issuer issuer))
)

;; Public functions
(define-public (add-authorized-issuer (issuer principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (map-set authorized-issuers issuer true))
    )
)

(define-public (issue-certification (recipient principal) 
                                  (title (string-ascii 64))
                                  (description (string-ascii 256))
                                  (validity-period uint))
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
                revoked: false
            }
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

(define-read-only (get-authorized-issuer (issuer principal))
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