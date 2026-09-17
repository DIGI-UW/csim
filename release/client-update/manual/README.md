# Manual CSiM dashboard update

These three files update the existing CSiM Individual Data dashboard through
the official Superset 6.1.0 interface. They contain dashboard definitions and
saved reporting queries. They do not contain uploaded reporting records or a
database password.

Import the files in this exact order:

1. In **Datasets**, select **Import dataset** and import
   `01-csim-reporting-datasets.zip`. Enable overwrite when Superset offers it.
2. In **Charts**, select **Import chart** and import
   `02-csim-dashboard-charts.zip`. Enable overwrite.
3. In **Dashboards**, select **Import dashboard** and import
   `03-csim-dashboard.zip`. Enable overwrite.

Superset may ask for the existing PostgreSQL connection password while reading
the definitions. Use the password for the destination's existing `PostgreSQL`
connection. The import reuses that connection; it does not replace the client's
reporting database.

After the third import, open the existing CSiM Individual Data dashboard and
check the expected filters and charts. Superset maps the filter targets and
excluded-chart scope to the destination during import. To inspect or change a
filter later, open **Edit dashboard**, open the filter bar's settings menu, and
choose **Add or edit filters**. Do not save filters merely to complete the
installation.

Do not import the files out of order. Superset 6.1.0 does not update a
dashboard's existing datasets and charts when they arrive only as dashboard
dependencies; the separate first and second imports perform those updates.

The server must already have SQL template processing enabled. The optional
instance-wide Time Unit restriction is described in the public installation
guide: https://design.csim.uwdigi.org/install.html
