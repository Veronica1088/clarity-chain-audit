;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-certified (err u101))
(define-constant err-already-registered (err u102))
(define-constant err-not-found (err u103))

;; Data structures
(define-map auditors
  principal
  {certified: bool, reputation: uint}
)

(define-map contracts 
  principal
  {registered: bool, last-audit: uint, status: (string-ascii 20)}
)

(define-map audit-reports
  {contract: principal, audit-id: uint}
  {auditor: principal, timestamp: uint, findings: (string-utf8 500), severity: uint}
)

;; Data vars
(define-data-var audit-nonce uint u0)

;; Register auditor - owner only
(define-public (register-auditor (auditor principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set auditors auditor {certified: true, reputation: u0}))
  )
)

;; Register contract for audit
(define-public (register-contract (contract principal))
  (begin
    (asserts! (is-none (map-get? contracts contract)) err-already-registered)
    (ok (map-set contracts contract {registered: true, last-audit: u0, status: "pending"}))
  )
)

;; Submit audit report
(define-public (submit-audit (contract principal) (findings (string-utf8 500)) (severity uint))
  (let
    (
      (auditor-data (unwrap! (map-get? auditors tx-sender) err-not-certified))
      (audit-id (var-get audit-nonce))
    )
    (asserts! (get certified auditor-data) err-not-certified)
    (map-set audit-reports 
      {contract: contract, audit-id: audit-id}
      {auditor: tx-sender, timestamp: block-height, findings: findings, severity: severity}
    )
    (map-set contracts contract 
      {registered: true, last-audit: block-height, status: (if (> severity u5) "failed" "passed")}
    )
    (var-set audit-nonce (+ audit-id u1))
    (ok true)
  )
)

;; Read only functions
(define-read-only (get-contract-status (contract principal))
  (map-get? contracts contract)
)

(define-read-only (get-audit-report (contract principal) (audit-id uint))
  (map-get? audit-reports {contract: contract, audit-id: audit-id})
)

(define-read-only (get-auditor-info (auditor principal))
  (map-get? auditors auditor)
)
