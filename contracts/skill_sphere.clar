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
(define-constant err-invalid-date (err u109))
(define-constant err-invalid-rating (err u110))

;; New constants
(define-constant max-rating u5)
(define-constant max-stake u1000000000) ;; 1000 STX maximum stake
(define-constant page-size u50)

;; [Previous data vars and maps remain unchanged]

;; Enhanced validation functions
(define-private (validate-dates (issue-date uint) (expiry-date uint))
  (and
    (>= issue-date block-height)
    (> expiry-date issue-date)
  )
)

(define-private (validate-rating (rating uint))
  (and (> rating u0) (<= rating max-rating))
)

;; Enhanced endorsement function
(define-public (add-endorsement 
  (cert-id uint) 
  (comment (string-ascii 256)) 
  (rating uint)
)
  (let (
    (certification (unwrap! (map-get? certifications {cert-id: cert-id}) err-not-found))
  )
    (asserts! (validate-rating rating) err-invalid-rating)
    (asserts! (validate-string-length comment) err-invalid-input)
    (ok (map-set endorsements
      {cert-id: cert-id, endorser: tx-sender}
      {
        comment: comment,
        timestamp: block-height,
        rating: rating
      }
    ))
  )
)

;; New query function
(define-read-only (get-recipient-certifications (recipient principal) (page uint))
  (let (
    (start (* page page-size))
    (end (+ start page-size))
  )
    (filter certification-matches-recipient
      (map unwrap-certification
        (get-certification-range start end))
    )
  )
)

(define-private (certification-matches-recipient (cert {
  issuer: principal,
  recipient: principal,
  title: (string-ascii 64),
  description: (string-ascii 256),
  issue-date: uint,
  expiry-date: uint,
  revoked: bool,
  transferable: bool,
  metadata: (optional (string-ascii 512))
}))
  (is-eq (get recipient cert) tx-sender)
)

;; [Rest of the original contract functions remain unchanged]
