# 🧠 Accounting Database System (PostgreSQL)

A modular **Accounting database system** designed to handle inventory, sales, and financial transactions and more using PostgreSQL.

---

## 🚀 Features

* 📦 **Inventory Management**

  * Tracks stock movement across warehouses
  * Supports purchases, sales, transfers, and returns
  * Inventory cost flow (LIFO, FIFO, AVCO)

* 💰 **Accounting System**

  * Double-entry bookkeeping (Debit/Credit)
  * Automatic journal entry generation

* 🧾 **Accounts Receivable / Payable**

  * Tracks customer balances and supplier obligations
  * Supports payment status and due dates

* 🥞 **Multitenant client and Chart of Account**

  * Multiple Clients can simultaneously operate 
  * Multiple Chart of account custom made for every Clients needs


* ⚙️ **Stored Procedures (PL/pgSQL)**

  * Centralized transaction processing
  * Modular design (Inventory + Accounting modules)

* 🧩 **Partitioned Tables**

  * Scalable handling of financial data using date-based partitioning

* 📊 **Reporting & Dashboard Queries**

  * Inventory levels
  * Revenue and profit
  * Aging reports (AR/AP)

* 🫆 **Audit Logs / Extended Audit Logs**

  * Audit Hash Code Chain
  * Automatic Recording Every Transaction
  * Summary Import Logs

* 📋 **Audit Trail**
 
  * Transaction Life Cycle
  * Import Session

* 📝 **Compliance**
  
  * Compliance log
  * import compliance log

* 🗂 **Staging**
  
   * Data Testing
   * Sanitation
   * Validation
   * Approval
    
* 🛡️ **Trigger Guard**

   * Prevent direct operation to table
   * Need specific setting to perform CRUD Operations

---

## 🏗️ System Architecture

```
[CSV, API, SPREAD_SHEET_IMPORT]
      ↓
[Staging] -> [Record Lineage]
      ↓
[Sanitation] 
      ↓
[Validations] -> [Record Lineage]
      ↓
[Approval Chain] -> [Record Lineage]
      ↓
[Posting] -> [Record Lineage]
      ↓
[ AR / AP / Inventory Transactions and so on] -> [Audit Log]
      ↓
[Journals] -> [Audit Log]
      ↓
[Accounting Module/Inventory Module] -> [Audit Log]
      ↓
[Lineage] 

```

---

## 🧠 Key Concepts Demonstrated

* Relational Database Design (Normalization, Constraints)
* Partitioning Strategy (Range Partitioning by Date)
* Composite Keys in Partitioned Tables
* Foreign Key Integrity across modules
* Financial Data Modeling (ERP-style logic)
* Query Optimization using Indexes
* Modular Stored Procedure Design
* Audit Log for Every Table CRUD Operations
* Recording Data Lineage (From Staging to Production)
* Idempotency key for tracking
* Code Hashing Chain
* Sanitation, Validation and Approval Chain at Staging 
---

## 🛠️ Tech Stack

* **Database:** PostgreSQL
* **Language:** SQL / PLpgSQL
* **Tools:** pgAdmin / DBeaver (optional)

## 💼 Business Value

This system simulates a real Accounting backend where:

* Inventory transactions automatically affect financial records
* Sales generate accounts receivable
* Purchases generate accounts payable
* Financial reports can be derived from journal entries
* Record Data Lineage From Staging to Production to Archive
* Multiple Tenant and custom made Chart of Account
* Record Operations Logs with Hash Chain
* Idempotency key to prevent duplicate process
* Staging area (Sanitation, Validations and Approval) Before posting to productions table
* Compliance log (for every successful and failure transactions)
* Import log (Record every successful and failure import transaction)
* Guard any data from direct transaction to void by passing the process
* Transaction Lifecycle data tracking inside production schema
  
---

## 📌 Future Improvements

* High Availability (HA)
* Disaster Recovery (DR)
* Logical replication
* Backup strategies
* Query tuning with EXPLAIN ANALYZE
* PostgreSQL extensions
* Row-Level Security (RLS)
* Database migrations
* CI/CD for database deployments
* Performance benchmarking
* Monitoring with tools like pg_stat_statements
* Event-driven architectures and messaging
* Archiving
---
