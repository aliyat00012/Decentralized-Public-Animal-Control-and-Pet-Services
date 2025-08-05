;; Adoption Process Management Contract
;; Facilitates pet adoptions and tracks animal welfare outcomes

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-ALREADY-EXISTS (err u301))
(define-constant ERR-NOT-FOUND (err u302))
(define-constant ERR-INVALID-INPUT (err u303))
(define-constant ERR-APPLICATION-PENDING (err u304))
(define-constant ERR-ANIMAL-NOT-AVAILABLE (err u305))
(define-constant ERR-INSUFFICIENT-SCORE (err u306))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Application status constants
(define-constant STATUS-SUBMITTED u1)
(define-constant STATUS-UNDER-REVIEW u2)
(define-constant STATUS-APPROVED u3)
(define-constant STATUS-REJECTED u4)
(define-constant STATUS-COMPLETED u5)

;; Data variables
(define-data-var next-application-id uint u1)
(define-data-var next-adoption-id uint u1)
(define-data-var total-applications uint u0)
(define-data-var total-adoptions uint u0)
(define-data-var minimum-approval-score uint u70)

;; Adoption applications
(define-map adoption-applications
  { application-id: uint }
  {
    applicant: principal,
    animal-id: uint,
    applicant-name: (string-ascii 50),
    address: (string-ascii 100),
    phone: (string-ascii 20),
    email: (string-ascii 50),
    housing-type: (string-ascii 30),
    has-yard: bool,
    other-pets: (string-ascii 100),
    experience-level: uint,
    application-date: (string-ascii 10),
    status: uint,
    reviewer: (optional principal),
    review-notes: (string-ascii 200),
    approval-score: uint
  }
)

;; Available animals for adoption
(define-map available-animals
  { animal-id: uint }
  {
    name: (string-ascii 50),
    species: (string-ascii 20),
    breed: (string-ascii 50),
    age: uint,
    size: (string-ascii 20),
    temperament: (string-ascii 100),
    special-needs: (string-ascii 100),
    adoption-fee: uint,
    is-available: bool,
    shelter-id: uint,
    intake-date: (string-ascii 10)
  }
)

;; Completed adoptions
(define-map adoptions
  { adoption-id: uint }
  {
    application-id: uint,
    animal-id: uint,
    adopter: principal,
    adoption-date: (string-ascii 10),
    adoption-fee-paid: uint,
    follow-up-required: bool,
    follow-up-date: (string-ascii 10),
    welfare-status: (string-ascii 50)
  }
)

;; Adoption follow-ups
(define-map adoption-followups
  { adoption-id: uint }
  {
    follow-up-date: (string-ascii 10),
    animal-condition: (string-ascii 100),
    living-situation: (string-ascii 100),
    behavioral-issues: (string-ascii 100),
    veterinary-care: (string-ascii 100),
    overall-welfare-score: uint,
    needs-intervention: bool,
    notes: (string-ascii 200)
  }
)

;; Applicant screening criteria
(define-map screening-criteria
  { criteria-id: uint }
  {
    housing-score: uint,
    experience-score: uint,
    reference-score: uint,
    financial-score: uint,
    total-score: uint,
    is-approved: bool
  }
)

;; Public functions

;; Submit adoption application
(define-public (submit-application
  (animal-id uint)
  (applicant-name (string-ascii 50))
  (address (string-ascii 100))
  (phone (string-ascii 20))
  (email (string-ascii 50))
  (housing-type (string-ascii 30))
  (has-yard bool)
  (other-pets (string-ascii 100))
  (experience-level uint))
  (let
    (
      (application-id (var-get next-application-id))
      (animal-data (unwrap! (map-get? available-animals { animal-id: animal-id }) ERR-NOT-FOUND))
      (current-date "2024-01-01")
    )
    (asserts! (get is-available animal-data) ERR-ANIMAL-NOT-AVAILABLE)
    (asserts! (> (len applicant-name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len address) u0) ERR-INVALID-INPUT)
    (asserts! (<= experience-level u5) ERR-INVALID-INPUT)

    ;; Create application
    (map-set adoption-applications
      { application-id: application-id }
      {
        applicant: tx-sender,
        animal-id: animal-id,
        applicant-name: applicant-name,
        address: address,
        phone: phone,
        email: email,
        housing-type: housing-type,
        has-yard: has-yard,
        other-pets: other-pets,
        experience-level: experience-level,
        application-date: current-date,
        status: STATUS-SUBMITTED,
        reviewer: none,
        review-notes: "",
        approval-score: u0
      }
    )

    ;; Update counters
    (var-set next-application-id (+ application-id u1))
    (var-set total-applications (+ (var-get total-applications) u1))

    (ok application-id)
  )
)

;; Review application (admin only)
(define-public (review-application
  (application-id uint)
  (housing-score uint)
  (experience-score uint)
  (reference-score uint)
  (financial-score uint)
  (review-notes (string-ascii 200)))
  (let
    (
      (application-data (unwrap! (map-get? adoption-applications { application-id: application-id }) ERR-NOT-FOUND))
      (total-score (+ housing-score (+ experience-score (+ reference-score financial-score))))
      (is-approved (>= total-score (var-get minimum-approval-score)))
      (new-status (if is-approved STATUS-APPROVED STATUS-REJECTED))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status application-data) STATUS-SUBMITTED) ERR-INVALID-INPUT)
    (asserts! (<= housing-score u25) ERR-INVALID-INPUT)
    (asserts! (<= experience-score u25) ERR-INVALID-INPUT)
    (asserts! (<= reference-score u25) ERR-INVALID-INPUT)
    (asserts! (<= financial-score u25) ERR-INVALID-INPUT)

    ;; Update application
    (map-set adoption-applications
      { application-id: application-id }
      (merge application-data {
        status: new-status,
        reviewer: (some tx-sender),
        review-notes: review-notes,
        approval-score: total-score
      })
    )

    ;; Store screening criteria
    (map-set screening-criteria
      { criteria-id: application-id }
      {
        housing-score: housing-score,
        experience-score: experience-score,
        reference-score: reference-score,
        financial-score: financial-score,
        total-score: total-score,
        is-approved: is-approved
      }
    )

    (ok is-approved)
  )
)

;; Complete adoption
(define-public (complete-adoption (application-id uint) (adoption-fee-paid uint))
  (let
    (
      (application-data (unwrap! (map-get? adoption-applications { application-id: application-id }) ERR-NOT-FOUND))
      (animal-data (unwrap! (map-get? available-animals { animal-id: (get animal-id application-data) }) ERR-NOT-FOUND))
      (adoption-id (var-get next-adoption-id))
      (current-date "2024-01-01")
      (follow-up-date "2024-02-01")
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-eq (get status application-data) STATUS-APPROVED) ERR-INVALID-INPUT)
    (asserts! (get is-available animal-data) ERR-ANIMAL-NOT-AVAILABLE)
    (asserts! (>= adoption-fee-paid (get adoption-fee animal-data)) ERR-INVALID-INPUT)

    ;; Create adoption record
    (map-set adoptions
      { adoption-id: adoption-id }
      {
        application-id: application-id,
        animal-id: (get animal-id application-data),
        adopter: (get applicant application-data),
        adoption-date: current-date,
        adoption-fee-paid: adoption-fee-paid,
        follow-up-required: true,
        follow-up-date: follow-up-date,
        welfare-status: "Good"
      }
    )

    ;; Update application status
    (map-set adoption-applications
      { application-id: application-id }
      (merge application-data { status: STATUS-COMPLETED })
    )

    ;; Mark animal as adopted
    (map-set available-animals
      { animal-id: (get animal-id application-data) }
      (merge animal-data { is-available: false })
    )

    ;; Update counters
    (var-set next-adoption-id (+ adoption-id u1))
    (var-set total-adoptions (+ (var-get total-adoptions) u1))

    (ok adoption-id)
  )
)

;; Add animal for adoption
(define-public (add-animal-for-adoption
  (name (string-ascii 50))
  (species (string-ascii 20))
  (breed (string-ascii 50))
  (age uint)
  (size (string-ascii 20))
  (temperament (string-ascii 100))
  (special-needs (string-ascii 100))
  (adoption-fee uint)
  (shelter-id uint))
  (let
    (
      (animal-id (var-get next-application-id))
      (current-date "2024-01-01")
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (> (len species) u0) ERR-INVALID-INPUT)

    (map-set available-animals
      { animal-id: animal-id }
      {
        name: name,
        species: species,
        breed: breed,
        age: age,
        size: size,
        temperament: temperament,
        special-needs: special-needs,
        adoption-fee: adoption-fee,
        is-available: true,
        shelter-id: shelter-id,
        intake-date: current-date
      }
    )

    (ok animal-id)
  )
)

;; Record follow-up visit
(define-public (record-followup
  (adoption-id uint)
  (animal-condition (string-ascii 100))
  (living-situation (string-ascii 100))
  (behavioral-issues (string-ascii 100))
  (veterinary-care (string-ascii 100))
  (overall-welfare-score uint)
  (notes (string-ascii 200)))
  (let
    (
      (adoption-data (unwrap! (map-get? adoptions { adoption-id: adoption-id }) ERR-NOT-FOUND))
      (current-date "2024-01-01")
      (needs-intervention (< overall-welfare-score u60))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= overall-welfare-score u100) ERR-INVALID-INPUT)

    (map-set adoption-followups
      { adoption-id: adoption-id }
      {
        follow-up-date: current-date,
        animal-condition: animal-condition,
        living-situation: living-situation,
        behavioral-issues: behavioral-issues,
        veterinary-care: veterinary-care,
        overall-welfare-score: overall-welfare-score,
        needs-intervention: needs-intervention,
        notes: notes
      }
    )

    ;; Update adoption record
    (map-set adoptions
      { adoption-id: adoption-id }
      (merge adoption-data {
        follow-up-required: needs-intervention,
        welfare-status: (if needs-intervention "Needs Attention" "Good")
      })
    )

    (ok true)
  )
)

;; Read-only functions

;; Get application details
(define-read-only (get-application (application-id uint))
  (map-get? adoption-applications { application-id: application-id })
)

;; Get available animal
(define-read-only (get-available-animal (animal-id uint))
  (map-get? available-animals { animal-id: animal-id })
)

;; Get adoption details
(define-read-only (get-adoption (adoption-id uint))
  (map-get? adoptions { adoption-id: adoption-id })
)

;; Get follow-up information
(define-read-only (get-followup (adoption-id uint))
  (map-get? adoption-followups { adoption-id: adoption-id })
)

;; Get screening criteria
(define-read-only (get-screening-criteria (criteria-id uint))
  (map-get? screening-criteria { criteria-id: criteria-id })
)

;; Get total applications
(define-read-only (get-total-applications)
  (var-get total-applications)
)

;; Get total adoptions
(define-read-only (get-total-adoptions)
  (var-get total-adoptions)
)

;; Get minimum approval score
(define-read-only (get-minimum-approval-score)
  (var-get minimum-approval-score)
)

;; Check if animal is available
(define-read-only (is-animal-available (animal-id uint))
  (match (map-get? available-animals { animal-id: animal-id })
    animal-data (get is-available animal-data)
    false
  )
)
