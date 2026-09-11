# Demonstration database

`v1_schema_dump.sql` is the user-supplied CSiM demonstration database used by
the reproducible dashboard. Its SHA-256 is:

`6726a084cc7b3b2daa288423ae9f8123b5f865867795278043ce5d9f77f542f9`

The restore command is explicit: `bash csim.sh demo-restore`. Normal dashboard
imports and updates do not restore or replace this database.
