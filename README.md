# TMU Geospatial Lab: Snowflake Geospatial Operations

This lab introduces geospatial operations in Snowflake for students who are already familiar with geospatial concepts but new to Snowflake. The lab covers Snowflake's native GEOGRAPHY data type, spatial functions, and practical applications using OpenStreetMap data for New York City.

## Prerequisites

- Internet access on a computer with a web browser
- Basic understanding of geospatial concepts (coordinate systems, geometries, spatial operations)
- Familiarity with SQL

## Initial Setup

### Step 1: Create a Snowflake Trial Account

1. Navigate to [https://signup.snowflake.com/?trial=student](https://signup.snowflake.com/?trial=student)
2. Create your own trial account
3. **Important**: You will need to go through email verification, so make sure you enter an email address that you have access to

### Step 2: Configure Your Trial Account

When setting up your account, select the following options:

- **Edition**: Enterprise
- **Cloud Provider**: AWS
- **Region**: US East (Northern Virginia)

### Step 3: Set Up Your Account

1. **First-time Login**:
   - If this is your first time logging into the Snowflake UI, you will be prompted to enter your account name or account URL
   - The account URL contains your account name and potentially the region
   - You can find your account URL in the email that was sent to you after you signed up for the trial

2. **Sign In**:
   - Click "Sign-in" and enter your username and password
   - You should now be in the Snowflake web interface

For more information on Snowflake features and setup, visit: [https://docs.snowflake.com/en/user-guide/setup](https://docs.snowflake.com/en/user-guide/setup)

### Step 4: Increase Your Account Permissions

The Snowflake web interface has many features, but for this lab, you need to switch your current role from the default `SYSADMIN` to `ACCOUNTADMIN`. This increase in permissions will allow you to create shared databases from Snowflake Marketplace listings.

**To change your role**:
1. In the Snowflake web interface, look for the role selector (usually in the top-right corner or in the left sidebar)
2. Click on the current role (likely `SYSADMIN`)
3. Select `ACCOUNTADMIN` from the dropdown menu

## Lab Overview

This lab is based on Snowflake's official geospatial guide: [Getting Started with Geospatial Geography](https://www.snowflake.com/en/developers/guides/getting-started-with-geospatial-geography/?index=..%2F..index)

### What You'll Learn

1. **Snowflake Infrastructure**
   - Understanding warehouses (compute resources)
   - Working with databases, schemas, and tables
   - Using Snowflake Marketplace data

2. **GEOGRAPHY Data Type**
   - Understanding Snowflake's GEOGRAPHY type (spherical geometry, WGS84)
   - Working with different formats: GeoJSON, WKT, WKB
   - Converting between formats

2b. **GEOMETRY Data Type (Add-on Section)**
   - Understanding GEOMETRY type (planar/Euclidean geometry)
   - When to use GEOMETRY vs GEOGRAPHY
   - Working with Spatial Reference System Identifiers (SRIDs)
   - Converting between GEOGRAPHY and GEOMETRY
   - Coordinate system transformations with ST_TRANSFORM()
   - Comparing spherical vs planar distance calculations

3. **Data Management**
   - Unloading data to Snowflake stages
   - Loading geospatial data into tables
   - Working with file formats

4. **Geospatial Functions**
   - **Accessors**: ST_X(), ST_Y() - extracting coordinates
   - **Constructors**: TO_GEOGRAPHY(), TO_GEOMETRY(), ST_MAKEPOINT(), ST_MAKELINE(), ST_MAKEPOLYGON()
   - **Transformations**: ST_COLLECT() - aggregating geometries, ST_TRANSFORM() - coordinate system transformations
   - **Measurements**: ST_DISTANCE(), ST_LENGTH(), ST_PERIMETER(), ST_AREA()
   - **Spatial Predicates**: ST_DWITHIN(), ST_WITHIN()

5. **Spatial Queries**
   - Finding nearby locations
   - Spatial joins
   - Creating routes and polygons
   - Finding points within polygons

### Lab Scenario

You'll work through a practical scenario: planning a shopping trip in New York City near Times Square. You'll find the closest Best Buy, liquor store, and coffee shop, then optimize your route and explore shops along the way.

## Running the Lab

1. Open the `lab.sql` file in Snowflake's web interface (using the Worksheets feature)
2. Execute the SQL statements sequentially
3. Read the comments carefully - they explain both Snowflake-specific concepts and geospatial operations
4. Experiment with the queries to understand how they work

## File Structure

- `lab.sql` - Complete lab script with detailed comments and explanations
- `README.md` - This file

## Key Snowflake Concepts for Geospatial Users

If you're coming from PostGIS or other geospatial databases, here are some important differences:

- **Two Geospatial Types**: Snowflake supports both GEOGRAPHY (spherical) and GEOMETRY (planar) types, similar to PostGIS
  - **GEOGRAPHY**: Always uses WGS84, great-circle calculations, best for GPS/web data
  - **GEOMETRY**: Requires SRID specification, planar calculations, best for local/regional data
- **GEOGRAPHY Default**: Most examples use GEOGRAPHY (spherical) with great-circle distance calculations
- **Longitude First**: Always use longitude before latitude (x, y) convention
- **Warehouses**: Compute resources that execute queries (separate from storage)
- **Stages**: File storage locations (internal or external to cloud storage)

## Getting Help

- **Snowflake Documentation**: [https://docs.snowflake.com](https://docs.snowflake.com)
- **Geospatial Functions Reference**: [https://docs.snowflake.com/en/sql-reference/functions-geospatial](https://docs.snowflake.com/en/sql-reference/functions-geospatial)
- **Snowflake Community**: [https://community.snowflake.com](https://community.snowflake.com)

## Notes

- The lab uses data from Snowflake Marketplace (OpenStreetMap New York data)
- All distances are calculated in meters using great-circle distance
- The lab assumes you're working in the Snowflake web interface (Worksheets)
- Make sure you have ACCOUNTADMIN role to access Marketplace data

## Troubleshooting

**Can't access Marketplace data?**
- Ensure you're using the ACCOUNTADMIN role
- Check that you've selected the correct region (US East - Northern Virginia)

**Warehouse not starting?**
- Warehouses auto-suspend after inactivity to save costs
- They will auto-resume when you run a query
- Check the warehouse status in the web interface

**Queries running slowly?**
- Make sure your warehouse is running (not suspended)
- Check the warehouse size - you may need a larger size for better performance

---

**Lab Created**: November 2024  
**For**: TMU Geospatial Lab  
**Based on**: [Snowflake Geospatial Guide](https://www.snowflake.com/en/developers/guides/getting-started-with-geospatial-geography/)

