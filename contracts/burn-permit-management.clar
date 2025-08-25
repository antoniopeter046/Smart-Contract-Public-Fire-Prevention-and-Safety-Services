;; Burn Permit Management Contract
;; Issues and tracks permits for controlled burns and outdoor fires

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-PERMIT-NOT-FOUND (err u401))
(define-constant ERR-INVALID-DATE (err u402))
(define-constant ERR-BURN-SEASON-CLOSED (err u403))
(define-constant ERR-WEATHER-RESTRICTION (err u404))
(define-constant ERR-PERMIT-EXPIRED (err u405))

;; Data Variables
(define-data-var next-permit-id uint u1)
(define-data-var burn-season-active bool true)
(define-data-var weather-restriction-active bool false)
(define-data-var permit-fee uint u50)

;; Data Maps
(define-map burn-permits
  { permit-id: uint }
  {
    applicant: principal,
    property-address: (string-ascii 200),
    burn-type: (string-ascii 50),
    burn-purpose: (string-ascii 100),
    requested-date: uint,
    approved-date: (optional uint),
    expiry-date: (optional uint),
    status: (string-ascii 20),
    conditions: (string-ascii 300),
    fire-safety-equipment: (string-ascii 200),
    estimated-size: (string-ascii 50),
    weather-dependent: bool
  }
)

(define-map permit-inspections
  { permit-id: uint }
  {
    inspector: principal,
    inspection-date: uint,
    pre-burn-approved: bool,
    post-burn-completed: bool,
    violations-noted: (optional (string-ascii 300))
  }
)

(define-map authorized-inspectors
  { inspector: principal }
  { authorized: bool }
)

(define-map seasonal-restrictions
  { season: (string-ascii 20) }
  {
    start-date: uint,
    end-date: uint,
    restrictions: (string-ascii 200)
  }
)

;; Authorization Functions
(define-public (authorize-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-inspectors { inspector: inspector } { authorized: true }))
  )
)

(define-public (set-burn-season-status (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (var-set burn-season-active active))
  )
)

(define-public (set-weather-restriction (active bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (var-set weather-restriction-active active))
  )
)

;; Permit Application
(define-public (apply-for-permit
  (property-address (string-ascii 200))
  (burn-type (string-ascii 50))
  (burn-purpose (string-ascii 100))
  (requested-date uint)
  (fire-safety-equipment (string-ascii 200))
  (estimated-size (string-ascii 50))
  (weather-dependent bool))
  (let ((permit-id (var-get next-permit-id)))
    (begin
      (asserts! (var-get burn-season-active) ERR-BURN-SEASON-CLOSED)
      (asserts! (> requested-date block-height) ERR-INVALID-DATE)

      (map-set burn-permits
        { permit-id: permit-id }
        {
          applicant: tx-sender,
          property-address: property-address,
          burn-type: burn-type,
          burn-purpose: burn-purpose,
          requested-date: requested-date,
          approved-date: none,
          expiry-date: none,
          status: "pending",
          conditions: "",
          fire-safety-equipment: fire-safety-equipment,
          estimated-size: estimated-size,
          weather-dependent: weather-dependent
        }
      )
      (var-set next-permit-id (+ permit-id u1))
      (ok permit-id)
    )
  )
)

;; Permit Approval
(define-public (approve-permit (permit-id uint) (conditions (string-ascii 300)) (validity-days uint))
  (let ((permit (unwrap! (map-get? burn-permits { permit-id: permit-id }) ERR-PERMIT-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status permit) "pending") ERR-NOT-AUTHORIZED)

      (map-set burn-permits
        { permit-id: permit-id }
        (merge permit {
          approved-date: (some block-height),
          expiry-date: (some (+ block-height validity-days)),
          status: "approved",
          conditions: conditions
        })
      )
      (ok true)
    )
  )
)

;; Permit Inspection
(define-public (schedule-inspection (permit-id uint) (inspector principal))
  (let ((permit (unwrap! (map-get? burn-permits { permit-id: permit-id }) ERR-PERMIT-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status permit) "approved") ERR-NOT-AUTHORIZED)
      (asserts! (default-to false (get authorized (map-get? authorized-inspectors { inspector: inspector }))) ERR-NOT-AUTHORIZED)

      (map-set permit-inspections
        { permit-id: permit-id }
        {
          inspector: inspector,
          inspection-date: block-height,
          pre-burn-approved: false,
          post-burn-completed: false,
          violations-noted: none
        }
      )
      (ok true)
    )
  )
)

;; Pre-burn Inspection
(define-public (complete-pre-burn-inspection (permit-id uint) (approved bool) (violations (optional (string-ascii 300))))
  (let ((inspection (unwrap! (map-get? permit-inspections { permit-id: permit-id }) ERR-PERMIT-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get inspector inspection)) ERR-NOT-AUTHORIZED)

      (map-set permit-inspections
        { permit-id: permit-id }
        (merge inspection {
          pre-burn-approved: approved,
          violations-noted: violations
        })
      )

      ;; Update permit status based on inspection
      (let ((permit (unwrap! (map-get? burn-permits { permit-id: permit-id }) ERR-PERMIT-NOT-FOUND)))
        (map-set burn-permits
          { permit-id: permit-id }
          (merge permit { status: (if approved "ready-to-burn" "inspection-failed") })
        )
      )
      (ok true)
    )
  )
)

;; Burn Execution
(define-public (report-burn-completion (permit-id uint))
  (let ((permit (unwrap! (map-get? burn-permits { permit-id: permit-id }) ERR-PERMIT-NOT-FOUND)))
    (begin
      (asserts! (is-eq tx-sender (get applicant permit)) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status permit) "ready-to-burn") ERR-NOT-AUTHORIZED)
      (asserts! (not (var-get weather-restriction-active)) ERR-WEATHER-RESTRICTION)

      ;; Check if permit is still valid
      (match (get expiry-date permit)
        expiry (asserts! (<= block-height expiry) ERR-PERMIT-EXPIRED)
        true
      )

      (map-set burn-permits
        { permit-id: permit-id }
        (merge permit { status: "burn-completed" })
      )
      (ok true)
    )
  )
)

;; Read-only Functions
(define-read-only (get-permit (permit-id uint))
  (map-get? burn-permits { permit-id: permit-id })
)

(define-read-only (get-permit-inspection (permit-id uint))
  (map-get? permit-inspections { permit-id: permit-id })
)

(define-read-only (is-burn-season-active)
  (var-get burn-season-active)
)

(define-read-only (is-weather-restriction-active)
  (var-get weather-restriction-active)
)

(define-read-only (get-permit-fee)
  (var-get permit-fee)
)

(define-read-only (is-permit-valid (permit-id uint))
  (match (map-get? burn-permits { permit-id: permit-id })
    permit (match (get expiry-date permit)
      expiry (and (> expiry block-height) (is-eq (get status permit) "ready-to-burn"))
      false
    )
    false
  )
)
