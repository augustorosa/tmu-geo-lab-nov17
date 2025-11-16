# TMU Geospatial Lab: Snowflake Geospatial Operations

This lab introduces geospatial operations in Snowflake for students who are already familiar with geospatial concepts but new to Snowflake. The lab covers Snowflake's native GEOGRAPHY and GEOMETRY data types, spatial functions, and practical applications using OpenStreetMap data for New York City. The main lab focuses on GEOGRAPHY (spherical geometry), with an add-on section exploring GEOMETRY (planar geometry) for advanced use cases.

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

2b. **GEOMETRY Data Type**
   - Understanding GEOMETRY type (planar/Euclidean geometry)
   - When to use GEOMETRY vs GEOGRAPHY:
     * Use GEOGRAPHY for GPS coordinates, global data, web mapping applications
     * Use GEOMETRY for local/regional data, CAD drawings, fast calculations
   - Working with Spatial Reference System Identifiers (SRIDs):
     * Common SRIDs: WGS84 (4326), Web Mercator (3857), State Plane (2263), UTM zones
     * Specifying SRID when creating GEOMETRY objects
   - Creating GEOMETRY objects using TO_GEOMETRY() with WKT strings and SRID
   - Converting between GEOGRAPHY and GEOMETRY:
     * GEOGRAPHY → GEOMETRY: Recreate using TO_GEOMETRY() with WKT and SRID 4326
     * GEOMETRY → GEOGRAPHY: Use TO_GEOGRAPHY() with GEOMETRY (only works if SRID is 4326)
   - GEOMETRY-specific functions:
     * ST_TRANSFORM() for coordinate system transformations
     * ST_AREA() for area calculations in coordinate system units
   - Comparing spherical vs planar distance calculations
   - Working with projected coordinate systems (State Plane, UTM)

1. **Data Management**
   - Unloading data to Snowflake stages
   - Loading geospatial data into tables
   - Working with file formats

2. **Geospatial Functions**
   - **Accessors**: ST_X(), ST_Y() - extracting coordinates
   - **Constructors**: TO_GEOGRAPHY(), TO_GEOMETRY(), ST_MAKEPOINT(), ST_MAKELINE(), ST_MAKEPOLYGON()
   - **Transformations**: ST_COLLECT() - aggregating geometries, ST_TRANSFORM() - coordinate system transformations
   - **Measurements**: ST_DISTANCE(), ST_LENGTH(), ST_PERIMETER(), ST_AREA()
   - **Spatial Predicates**: ST_DWITHIN(), ST_WITHIN()

3. **Spatial Queries**
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
  - **GEOGRAPHY**: Always uses WGS84 internally, great-circle calculations, best for GPS/web data, global analysis
  - **GEOMETRY**: Requires SRID specification, planar/Euclidean calculations, best for local/regional data, CAD, engineering
- **GEOGRAPHY Default**: Most examples in this lab use GEOGRAPHY (spherical) with great-circle distance calculations
- **TO_GEOGRAPHY() vs TO_GEOMETRY()**:
  - `TO_GEOGRAPHY()` does NOT take an SRID parameter - it always returns GEOGRAPHY (WGS84)
  - `TO_GEOMETRY()` requires an SRID parameter to specify the coordinate system
- **ST_MAKEPOINT()**: Creates GEOGRAPHY type, not GEOMETRY. Use `TO_GEOMETRY()` with WKT and SRID for GEOMETRY points
- **Type Conversions**:
  - You cannot directly cast GEOGRAPHY to GEOMETRY using `::geometry` syntax
  - Convert GEOGRAPHY → GEOMETRY by recreating with `TO_GEOMETRY()` using the WKT string
  - Convert GEOMETRY → GEOGRAPHY using `TO_GEOGRAPHY()` with GEOMETRY expression (only if SRID is 4326)
- **Longitude First**: Always use longitude before latitude (x, y) convention in WKT strings
- **Warehouses**: Compute resources that execute queries (separate from storage)
- **Stages**: File storage locations (internal or external to cloud storage)

## Additional Snowflake Geospatial Labs & Guides

Expand your geospatial knowledge with these additional Snowflake guides:

- **[Geo Analysis with GEOMETRY](https://www.snowflake.com/en/developers/guides/geo-analysis-geometry/)** - Deep dive into GEOMETRY data type, working with projected coordinate systems, and planar geometry operations

- **[Geospatial Data for Machine Learning](https://www.snowflake.com/en/developers/guides/geo-for-machine-learning/)** - Learn how to use geospatial data in ML workflows, feature engineering, and spatial ML models

- **[Using Precisely to Enrich Data](https://www.snowflake.com/en/developers/guides/using-precisely-enrich-data/)** - Explore how to enrich your geospatial data with location intelligence and demographic data

- **[Credit Card Fraud Detection with Snowflake ML Functions](https://www.snowflake.com/en/developers/guides/credit-card-fraud-detection-with-snowflake-ml-functions/)** - Advanced example combining geospatial analysis with machine learning for fraud detection

## Getting Help

- **Snowflake Documentation**: [https://docs.snowflake.com](https://docs.snowflake.com)
- **Geospatial Functions Reference**: [https://docs.snowflake.com/en/sql-reference/functions-geospatial](https://docs.snowflake.com/en/sql-reference/functions-geospatial)
- **Snowflake Community**: [https://community.snowflake.com](https://community.snowflake.com)

## Notes

- The lab uses data from Snowflake Marketplace (OpenStreetMap New York data)
- GEOGRAPHY distances are calculated in meters using great-circle distance (spherical geometry)
- GEOMETRY distances are calculated in the units of the coordinate system (planar/Euclidean geometry)
- The lab assumes you're working in the Snowflake web interface (Worksheets)
- Make sure you have ACCOUNTADMIN role to access Marketplace data
- The GEOMETRY section is an add-on that can be completed after mastering GEOGRAPHY concepts

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

