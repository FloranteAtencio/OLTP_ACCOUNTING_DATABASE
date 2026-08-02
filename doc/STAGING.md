# Staging 

---
## Purpose
  * Ensure a consistent data and uncorrupted data as possible.
  * Built for ground testing of data to sanitate validate and seek for approval of the higher positions before posting to production schema. 

---
## Challenges
  * A lot of data where bouncing back, corrupted data and inconsistent data.
  * Not all data are suitable to under go staging they are directly load at production schema.  
  * Every import Transactions should be log and compliance log should be record (success and fail)
  * Every stage should be log too
    
---
## Resolve
  * Create process to catch early inconsistent data to avoid corrupted data before they enter the production schema through sanitation, validation and approval. 
  * Data source file and every data are log for every successful and fail transaction for import session log
  * Data that are not suitable for staging schema will be log at lineage table for tracking (expecting all the data are consistent)
---

Why use Staging?

Reason:
Production tables should never receive raw imported data.

Trade-offs:
+ Better validation
+ Approval workflow
- More storage
- Slightly slower imports

 
