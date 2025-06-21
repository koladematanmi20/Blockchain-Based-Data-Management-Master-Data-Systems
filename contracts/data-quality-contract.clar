;; Data Quality Contract
;; Manages data quality standards and validation rules

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INVALID_QUALITY_SCORE (err u201))
(define-constant ERR_RULE_NOT_FOUND (err u202))

;; Quality rules
(define-map quality-rules
  { rule-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    min-score: uint,
    weight: uint,
    active: bool,
    created-by: principal,
    created-at: uint
  }
)

;; Data quality scores
(define-map quality-scores
  { data-id: (string-ascii 100) }
  {
    overall-score: uint,
    completeness: uint,
    accuracy: uint,
    consistency: uint,
    timeliness: uint,
    last-updated: uint,
    validated-by: principal
  }
)

(define-data-var next-rule-id uint u1)

;; Create quality rule
(define-public (create-quality-rule
  (name (string-ascii 100))
  (description (string-ascii 500))
  (min-score uint)
  (weight uint)
)
  (let ((rule-id (var-get next-rule-id)))
    (map-set quality-rules
      { rule-id: rule-id }
      {
        name: name,
        description: description,
        min-score: min-score,
        weight: weight,
        active: true,
        created-by: tx-sender,
        created-at: block-height
      }
    )
    (var-set next-rule-id (+ rule-id u1))
    (ok rule-id)
  )
)

;; Update quality score
(define-public (update-quality-score
  (data-id (string-ascii 100))
  (completeness uint)
  (accuracy uint)
  (consistency uint)
  (timeliness uint)
)
  (let ((overall-score (/ (+ completeness accuracy consistency timeliness) u4)))
    (if (and (<= completeness u100) (<= accuracy u100) (<= consistency u100) (<= timeliness u100))
      (begin
        (map-set quality-scores
          { data-id: data-id }
          {
            overall-score: overall-score,
            completeness: completeness,
            accuracy: accuracy,
            consistency: consistency,
            timeliness: timeliness,
            last-updated: block-height,
            validated-by: tx-sender
          }
        )
        (ok overall-score)
      )
      ERR_INVALID_QUALITY_SCORE
    )
  )
)

;; Get quality score
(define-read-only (get-quality-score (data-id (string-ascii 100)))
  (map-get? quality-scores { data-id: data-id })
)

;; Check if data meets quality threshold
(define-read-only (meets-quality-threshold (data-id (string-ascii 100)) (threshold uint))
  (match (map-get? quality-scores { data-id: data-id })
    score-data (>= (get overall-score score-data) threshold)
    false
  )
)

;; Get quality rule
(define-read-only (get-quality-rule (rule-id uint))
  (map-get? quality-rules { rule-id: rule-id })
)
