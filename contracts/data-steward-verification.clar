;; Data Steward Verification Contract
;; Manages verification and authorization of data stewards

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STEWARD (err u103))

;; Data steward information
(define-map stewards
  { steward: principal }
  {
    verified: bool,
    verification-date: uint,
    department: (string-ascii 50),
    permissions: uint
  }
)

;; Verification requests
(define-map verification-requests
  { request-id: uint }
  {
    steward: principal,
    requested-by: principal,
    status: (string-ascii 20),
    request-date: uint
  }
)

(define-data-var next-request-id uint u1)

;; Submit verification request
(define-public (request-verification (department (string-ascii 50)))
  (let ((request-id (var-get next-request-id)))
    (map-set verification-requests
      { request-id: request-id }
      {
        steward: tx-sender,
        requested-by: tx-sender,
        status: "pending",
        request-date: block-height
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

;; Verify data steward (only contract owner)
(define-public (verify-steward (steward principal) (department (string-ascii 50)) (permissions uint))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (map-set stewards
        { steward: steward }
        {
          verified: true,
          verification-date: block-height,
          department: department,
          permissions: permissions
        }
      )
      (ok true)
    )
    ERR_UNAUTHORIZED
  )
)

;; Check if steward is verified
(define-read-only (is-verified-steward (steward principal))
  (match (map-get? stewards { steward: steward })
    steward-data (get verified steward-data)
    false
  )
)

;; Get steward info
(define-read-only (get-steward-info (steward principal))
  (map-get? stewards { steward: steward })
)

;; Revoke steward verification
(define-public (revoke-verification (steward principal))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (begin
      (map-delete stewards { steward: steward })
      (ok true)
    )
    ERR_UNAUTHORIZED
  )
)
