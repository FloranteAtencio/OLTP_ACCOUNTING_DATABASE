import psycopg2
import json
import csv
import os
import sys

conn = psycopg2.connect(
    host = "localhost",
    database = "erp_db",
    user = "erp_admin",
    password = "p2r0o2d6uction!",
    port=5432
)

stg_table = 'stg_ar_imports'
session_id = 1


cur = conn.cursor()
try:
    print(f"🦽 Pending Validations Start!")
    try:        
        cur.execute(" CALL Staging.import_workflow_validation(%s)",
                (session_id,)
                )
        conn.commit()
        print(f"🎉 Validation Complete !")
    except Exception as inner_e:
        print(f"⚠️  procedure fail : {inner_e}")
            
except Exception as e:
    err_message = str(e)
    print(f"⚠️  Failed : {err_message}")

finally:

    print(f"🎉 Import Complete! Validations {session_id} ")

    if cur:
        cur.close()
    if conn:
        conn.close()
    print(" 🔒 Connections Closed")