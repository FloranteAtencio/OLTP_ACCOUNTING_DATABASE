# Auditing And Trigger

---
## Purpose
  * Track every changes or before it happened
  * Record Every changes for auditing purposes
  * To prevent directly operation to the table

---
## Challenges
  * By passing the process by direct transaction to the table
  * Tracking of who, when, and what operations happened to data
  * History logs data

---
## Resolve
  * Core Finance tables are protected against direct data manipulation. Business operations are executed exclusively through stored procedures. Database-level controls ensure that audit logging, lineage recording, compliance validation, and workflow management cannot be bypassed


  Why use Auditing?

  Reason:
  Every Production table shoul log every successful operations (create, update, and delete).

  Trade offs:
  + Better tracking
  + History Record
  - More storage
  - More Resource 