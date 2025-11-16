-- ============================================================================
-- SNOWFLAKE GEOSPATIAL LAB: Introduction to Geospatial Operations in Snowflake
-- ============================================================================
-- This lab introduces Snowflake's geospatial capabilities to geospatial experts
-- who are new to Snowflake. Snowflake is a cloud data warehouse that provides
-- native support for geospatial data types and functions following OGC standards.
--
-- Key Snowflake Concepts:
-- - WAREHOUSE: A compute resource that processes queries (similar to a database
--   server cluster, but in the cloud). Warehouses can be scaled up/down and
--   auto-suspend when not in use to save costs.
-- - ROLE: Snowflake uses role-based access control. ACCOUNTADMIN has full
--   administrative privileges.
--  Based on this Snowflake lab https://www.snowflake.com/en/developers/guides/getting-started-with-geospatial-geography/?index=..%2F..index
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Create a Warehouse
-- A warehouse in Snowflake is a compute cluster that executes SQL queries.
-- Unlike traditional databases, Snowflake separates storage from compute, allowing
-- you to scale them independently. This warehouse will be used to process all
-- geospatial queries in this lab.
CREATE OR REPLACE WAREHOUSE my_wh 
WITH WAREHOUSE_TYPE = 'STANDARD'      -- Standard warehouse type (vs. SNOWPARK-OPTIMIZED)
    WAREHOUSE_SIZE = 'XSMALL'         -- Smallest size, suitable for learning (can scale to 6XL)
    AUTO_SUSPEND = 60                 -- Automatically pause after 60 seconds of inactivity (saves costs)
    AUTO_RESUME = TRUE                -- Automatically resume when a query is submitted
    INITIALLY_SUSPENDED = TRUE        -- Start in suspended state (no compute costs until first query)
    RESOURCE_CONSTRAINT = STANDARD_GEN_2;  -- Use Gen2 compute resources (newer, more efficient)

-- ============================================================================
-- WORKING WITH SNOWFLAKE MARKETPLACE DATA
-- ============================================================================
-- Snowflake Marketplace provides pre-built datasets that you can use immediately.
-- The OSM_NEWYORK database contains OpenStreetMap data for New York City.
-- In Snowflake, a DATABASE contains SCHEMAS, which contain TABLES/VIEWS.
-- The three-part identifier is: database.schema.object_name

// Set the working database schema
-- This sets the default context so you don't need to fully qualify object names
use schema osm_newyork.new_york;

// Describe the v_osm_ny_shop_electronics view 
-- DESCRIBE shows the structure of a view/table, including column names and data types
-- This view contains electronics shops from OpenStreetMap data
desc view v_osm_ny_shop_electronics;

-- ============================================================================
-- SNOWFLAKE GEOGRAPHY OUTPUT FORMATS
-- ============================================================================
-- Snowflake stores geospatial data internally in a binary format, but can display
-- it in multiple standard formats. The GEOGRAPHY data type in Snowflake follows
-- OGC (Open Geospatial Consortium) standards and uses WGS84 coordinate system.
-- Unlike PostGIS which uses GEOMETRY (planar) and GEOGRAPHY (spherical), Snowflake
-- only has GEOGRAPHY type, which always uses spherical calculations (great circle).

// Set the output format to GeoJSON
-- GeoJSON is a JSON-based format commonly used in web mapping applications.
-- Snowflake can output GEOGRAPHY data in: GEOJSON, WKT, EWKT, WKB, EWKB
alter session set geography_output_format = 'GEOJSON';

// Query the v_osm_ny_shop_electronics view for rows of type 'node' (long/lat points)
-- In OpenStreetMap, 'node' represents a single point location (like a storefront)
-- The coordinates column is of type GEOGRAPHY and contains POINT geometries
select coordinates, name from v_osm_ny_shop_electronics where type = 'node' limit 25;

--keeping results: {
  "coordinates": [
    -7.393255960000000e+01,
    4.079556420000000e+01
  ],
  "type": "Point"
} --

// Query the v_osm_ny_shop_electronics view for rows of type 'way' (a collection of many points)
-- In OpenStreetMap, 'way' represents a line or polygon (a collection of connected points)
-- This could be a building footprint, road segment, or area boundary
select coordinates, name from v_osm_ny_shop_electronics where type = 'way' limit 25;


// Set the output format to WKT
-- WKT (Well-Known Text) is a human-readable text format for geospatial data.
-- Format: POINT(lon lat), LINESTRING(lon1 lat1, lon2 lat2), POLYGON(...), etc.
-- Note: Snowflake always uses longitude first, then latitude (unlike some systems)
alter session set geography_output_format = 'WKT';

-- Lets re-run the queries to see the same data in WKT format
// Query the v_osm_ny_shop_electronics view for rows of type 'node' (long/lat points)
select coordinates, name from v_osm_ny_shop_electronics where type = 'node' limit 25;

-- Example output: POINT(-77.706222 43.208417)
-- Format: POINT(longitude latitude) - longitude is always first in Snowflake

// Query the v_osm_ny_shop_electronics view for rows of type 'way' (a collection of many points)
select coordinates, name from v_osm_ny_shop_electronics where type = 'way' limit 25;

// Set the output format to WKB
-- WKB (Well-Known Binary) is a compact binary format for geospatial data.
-- It's efficient for storage and transmission but not human-readable.
-- WKB is often preferred for file storage because it's a single string with no delimiters.
alter session set geography_output_format = 'WKB';

-- Lets re-run the queries to see the same data in WKB format
// Query the v_osm_ny_shop_electronics view for rows of type 'node' (long/lat points)
select coordinates, name from v_osm_ny_shop_electronics where type = 'node' limit 25;

-- Example output: 0101000000CE6DC2BD326D53C018778368AD9A4540
-- This is a hexadecimal representation of the binary geometry data

// Query the v_osm_ny_shop_electronics view for rows of type 'way' (a collection of many points)
select coordinates, name from v_osm_ny_shop_electronics where type = 'way' limit 25;


-- ============================================================================
-- UNLOADING DATA TO SNOWFLAKE STAGES
-- ============================================================================
-- Snowflake uses "stages" for file storage. Stages are locations where you can
-- store files that Snowflake can read from or write to. There are three types:
-- 1. Internal stages: Stored within Snowflake (@~ = user stage, @table_name = table stage)
-- 2. External stages: Point to cloud storage (S3, Azure, GCS)
-- 3. Named stages: User-defined internal stages
-- The COPY INTO command can both load data FROM stages and unload data TO stages.

-- Lets load some more data

-- changing the format The WKB format is being chosen here for its simplicity within a file. 
-- Since WKB is a single alpha-numeric string with no delimiters, spaces, or other difficult 
-- characters, it is excellent for storing geospatial data in a file. That doesn't mean other 
-- formats are to be avoided in real-world use cases, but WKB will make your work easier in this guide.
alter session set geography_output_format = 'WKB';

-- unload some from the data we got from the marketplace
// Define the write location (@~/ = my user stage) and file name for the file 
-- @~/ refers to your user stage, a private internal stage unique to your user account
-- COPY INTO can write query results to a stage (unloading) or load from a stage (loading)
copy into @~/osm_ny_shop_electronics_all.csv 
// Define the query that represents the data output
-- This query selects all columns including the GEOGRAPHY coordinates column
from (select id,coordinates,name,type from v_osm_ny_shop_electronics) 
// Indicate the comma-delimited file format and tell it to double-quote strings
-- file_format specifies how to structure the output file
file_format=(type=csv field_optionally_enclosed_by='"') 
// Tell Snowflake to write one file and overwrite it if it already exists
-- single=true ensures one output file (vs. multiple files for large datasets)
-- overwrite=true replaces existing file if present
single=true overwrite=true;

-- now we unload more data, In this query, the parsers ST_X and ST_Y are extracting 
-- the longitude and latitude from a GEOGRAPHY POINT object. These parsers only accept 
-- single points as an input, so you had to filter the query on type = 'node'. 
-- In Snowflake, the 'x' coordinate is always the longitude and the 'y' coordinate is 
-- always the latitude, and as you will see in a future constructor, the longitude is 
-- always listed first.
-- ST_X() and ST_Y() are accessor functions that extract coordinates from POINT geometries.
-- They only work on POINT geometries, not LINESTRINGs or POLYGONs.
copy into @~/osm_ny_shop_electronics_points.csv 
from (
  select id,coordinates,name,type,st_x(coordinates),st_y(coordinates) 
  from v_osm_ny_shop_electronics where type='node'
) file_format=(type=csv field_optionally_enclosed_by='"') 
single=true overwrite=true;

-- lets check that files are there
-- LIST command shows files in a stage. The ~ after @ indicates user stage.
-- You can also use LIST @stage_name for named stages
list @~/osm;

-- we can direct select from data from the files. It can be slow.
-- You can query files directly from stages using SELECT. The $1, $2 syntax refers to
-- positional columns (column 1, column 2, etc.). This is useful for inspecting data
-- before loading into tables. Note: Querying stages directly can be slower than querying tables.
select $1,$2,$3,$4 from @~/osm_ny_shop_electronics_all.csv;

-- ============================================================================
-- CREATING YOUR OWN DATABASE AND LOADING DATA
-- ============================================================================
-- Now we'll create our own database to work with the data we've unloaded.
-- In Snowflake, databases are containers for schemas, which contain tables/views.
-- Unlike traditional databases, Snowflake databases are logical containers and
-- don't require you to manage physical storage locations.

-- Now lets create our own database

// Create a new local database
-- CREATE OR REPLACE will create the database if it doesn't exist, or replace it if it does
-- In Snowflake, databases are created instantly (no physical provisioning needed)
create or replace database geocodelab;
// Change your working schema to the public schema in that database
-- Every database has a PUBLIC schema by default. You can create additional schemas.
use schema geocodelab.public;
// Create a new file format in that schema
-- File formats are reusable definitions that specify how to parse files.
-- They're stored as objects in a schema and can be referenced by name.
-- This makes it easier to reuse the same format across multiple COPY commands.
create or replace file format geocsv type = 'csv' field_optionally_enclosed_by='"';
// Set the output format back to WKT
-- WKT is more readable than WKB for viewing results
alter session set geography_output_format = 'WKT';

-- lets again query to see. Notice the use of the TO_GEOGRAPHY constructor which tells 
-- Snowflake to interpret the WKB binary string as geospatial data and construct a GEOGRAPHY type. 
-- The WKT output format allows you to see this representation in a more readable form.
-- TO_GEOGRAPHY() is a constructor function that converts strings (WKT, WKB, GeoJSON) into GEOGRAPHY type.
-- When reading from a file, you need to explicitly convert string representations to GEOGRAPHY.
select $1,TO_GEOGRAPHY($2),$3,$4 
from @~/osm_ny_shop_electronics_all.csv 
(file_format => 'geocsv');

-- ============================================================================
-- LOADING DATA INTO TABLES
-- ============================================================================
-- Now we'll load the staged files into actual tables. Tables in Snowflake are
-- columnar storage optimized for analytics. The GEOGRAPHY data type is stored
-- efficiently and supports spatial indexing for fast queries.

// Create a new 'all' table in the current schema
-- GEOGRAPHY is Snowflake's geospatial data type. It stores geometries using WGS84.
-- Unlike PostGIS, Snowflake only has GEOGRAPHY (spherical), not GEOMETRY (planar).
create or replace table electronics_all 
(id number, coordinates geography, name string, type string);
// Load the 'all' file into the table
-- COPY INTO loads data from a stage into a table.
-- When the source file contains geospatial data in a recognized format (WKB, WKT, GeoJSON)
-- and the target column is GEOGRAPHY type, Snowflake automatically converts it.
copy into electronics_all from @~/osm_ny_shop_electronics_all.csv 
file_format=(format_name='geocsv');

-- at this point we loaded some more data, Now turn your attention to the other 'points' file. 
-- If you recall, you used ST_X and ST_Y to make discrete longitude and latitude columns in this file. 
-- It is not uncommon to receive data which contains these values in different columns, and you can 
-- use the ST_MAKEPOINT constructor to combine two discrete longitude and latitude columns into 
-- one GEOGRAPHY typed column. Run this query:

-- ST_MAKEPOINT(longitude, latitude) creates a POINT geometry from separate lon/lat values.
-- This is useful when your source data has coordinates in separate columns.
select $1,ST_MAKEPOINT($5,$6),$3,$4,$5,$6 
from @~/osm_ny_shop_electronics_points.csv 
(file_format => 'geocsv');

-- Notice in ST_MAKEPOINT that the longitude column is listed first. Despite the common 
-- verbal phrase "lat long," you always put longitude before latitude to represent a 
-- geospatial POINT object in Snowflake. This follows the OGC standard (x, y) convention.

--create a table and load the 'points' file into that table. Run these two queries.

// Create a new 'points' table in the current schema
-- This table includes both the GEOGRAPHY column and separate lon/lat columns for flexibility
create or replace table electronics_points 
(id number, coordinates geography, name string, type string, 
long number(38,7), lat number(38,7));
// Load the 'points' file into the table
-- When loading data that needs transformation (like combining lon/lat into GEOGRAPHY),
-- you must use a SELECT query in the COPY INTO statement. This is called a "transform query."
copy into electronics_points from (
  select $1,ST_MAKEPOINT($5,$6),$3,$4,$5,$6 
  from @~/osm_ny_shop_electronics_points.csv
) file_format=(format_name='geocsv');

-- note:In the 'all' file load statement, you didn't have to specify a query to load the file 
-- because when you have a column in a file that is already in a Snowflake supported geospatial 
-- format (WKB, WKT, GeoJSON), and load that value into a GEOGRAPHY typed column, Snowflake 
-- automatically does the geospatial construction for you. In the 'points' file, however, you 
-- must use a transform query to construct two discrete columns into a single GEOGRAPHY column 
-- using a geospatial constructor function.

select * from electronics_all;
select * from electronics_points;

use schema osm_newyork.new_york;
// Run just one of the below queries based on your preference
alter session set geography_output_format = 'GEOJSON';
alter session set geography_output_format = 'WKT';

-- ============================================================================
-- PRACTICAL GEOSPATIAL QUERIES: Finding Nearby Locations
-- ============================================================================
//The Scenario - Pretend that you are currently living in your apartment near Times Square 
-- in New York City. You need to make a shopping run to Best Buy and the liquor store, as 
-- well as grab a coffee at a coffee shop. Based on your current location, what are the 
-- closest stores or shops to do these errands, and are they the most optimal locations to 
-- go to collectively? Are there other shops you could stop at along the way? 

-- First, let's create a POINT geometry for our starting location (Times Square area)
-- TO_GEOGRAPHY() can parse WKT strings directly. Format: POINT(longitude latitude)
select to_geography('POINT(-73.986226 40.755702)');

-- lets look in a map https://geojson.io/#new&map=13.58/40.74498/-73.9961

-- ============================================================================
-- DISTANCE CALCULATIONS AND SPATIAL FILTERING
-- ============================================================================
-- ST_DISTANCE() calculates the great-circle distance between two geographies in meters.
-- ST_DWITHIN() is a spatial predicate that returns TRUE if two geometries are within
-- a specified distance of each other. It's more efficient than ST_DISTANCE() < threshold
-- because it can use spatial indexes. Both functions use spherical calculations (WGS84).

// Find the closest Best Buy
select id, coordinates, name, addr_housenumber, addr_street, 
// Use st_distance to calculate the distance between your location and Best Buy
-- ST_DISTANCE returns distance in meters. The ::number(6,2) casts to numeric with 2 decimals.
-- In Snowflake, :: is the cast operator (alternative to CAST() function).
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
// Filter just for Best Buys
where name = 'Best Buy' and 
// Filter for Best Buys that are within about a US mile (1600 meters)
-- ST_DWITHIN(geom1, geom2, distance_in_meters) is a spatial predicate function.
-- It returns TRUE/FALSE and is optimized for spatial indexing.
-- ST_MAKEPOINT(lon, lat) is equivalent to TO_GEOGRAPHY('POINT(lon lat)') but more concise.
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
// Order the results by the calculated distance and only return the lowest
-- ORDER BY 6 refers to the 6th column (distance_meters). LIMIT 1 gets the closest one.
order by 6 limit 1;

// Find the closest liquor store
select id, coordinates, name, addr_housenumber, addr_street, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'alcohol' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 6 limit 1;

// Find the closest coffee shop
select id, coordinates, name, addr_housenumber, addr_street, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 6 limit 1;

-- ============================================================================
-- GEOMETRY AGGREGATION: ST_COLLECT
-- ============================================================================
-- ST_COLLECT() aggregates multiple geometries into a single geometry collection.
-- When collecting POINTs, it creates a MULTIPOINT. When collecting LINESTRINGs,
-- it creates a MULTILINESTRING. This is useful for visualizing multiple locations
-- as a single geometry object.

-- Let's use ST_COLLECT to aggregate those 4 rows in the coordinates column into a single geospatial object, a MULTIPOINT.
// Create the CTE 'locations'
-- CTE (Common Table Expression) with WITH clause allows you to define temporary result sets
-- that can be referenced in the main query. This makes complex queries more readable.
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_food_beverages 
where shop = 'alcohol' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
// Query the CTE result set, aggregating the coordinates into one object
-- ST_COLLECT aggregates all POINT geometries into a MULTIPOINT geometry
select st_collect(coordinates) as multipoint from locations;


-- ============================================================================
-- CREATING LINESTRINGS: ST_MAKELINE
-- ============================================================================
-- The next thing you need to do is convert that MULTIPOINT object into a LINESTRING 
-- object using ST_MAKELINE, which takes a set of points as an input and turns them 
-- into a LINESTRING object. Whereas a MULTIPOINT has points with no assumed connection, 
-- the points in a LINESTRING will be interpreted as connected in the order they appear.
-- ST_MAKELINE() creates a LINESTRING by connecting points in sequence. This is useful
-- for creating paths, routes, or boundaries. The order of points matters - they will
-- be connected sequentially to form the line.
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_food_beverages 
where shop = 'alcohol' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
-- ST_MAKELINE can take a MULTIPOINT (from ST_COLLECT) and convert it to a LINESTRING.
-- Note: We're also adding the starting point again at the end to close the route.
select st_makeline(st_collect(coordinates),to_geography('POINT(-73.986226 40.755702)'))
as linestring from locations;

-- ============================================================================
-- MEASURING LINESTRING LENGTH: ST_LENGTH
-- ============================================================================
-- find out just how long by wrapping a ST_LENGTH function around the LINESTRING object, 
-- which will calculate the length of the line in meters
-- ST_LENGTH() calculates the total length of a LINESTRING or MULTILINESTRING in meters.
-- It uses great-circle distance calculations (spherical geometry) for accurate results
-- over long distances. For a route, this gives you the total travel distance.
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_food_beverages 
where shop = 'alcohol' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
// Feed the linestring into an st_length calculation
select st_length(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)')))
as length_meters from locations;

-- ============================================================================
-- SPATIAL JOINS
-- ============================================================================
-- Spatial joins combine data from multiple tables based on spatial relationships
-- rather than exact value matches. In Snowflake, you can use spatial predicates
-- (like ST_DWITHIN, ST_WITHIN, ST_INTERSECTS) in JOIN conditions.
-- Spatial joins are optimized using spatial indexes for performance.

-- Joins
// Join to electronics to find a liquor store closer to Best Buy
-- This query finds liquor stores near a specific Best Buy location, optimizing
-- the route by finding stores closer to Best Buy than to your starting point.
select fb.id,fb.coordinates,fb.name,fb.addr_housenumber,fb.addr_street,
// The st_distance calculation uses coordinates from both views
-- Calculate distance between Best Buy and the liquor store
st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
// The join is based on being within a certain distance
-- JOIN ON with ST_DWITHIN creates a spatial join. Only rows where geometries
-- are within 1600 meters of each other will be joined.
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
// Hard-coding the known Best Buy id below
-- Filter to a specific Best Buy location (found in previous query)
where e.id = 1428036403 and fb.shop = 'alcohol' 
// Ordering by distance and only showing the lowest
-- Find the closest liquor store to this Best Buy
order by 6 limit 1;

// Join to electronics to find a coffee shop closer to Best Buy
-- Similar query for coffee shops near Best Buy
select fb.id,fb.coordinates,fb.name,fb.addr_housenumber,fb.addr_street,
st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'coffee' 
order by 6 limit 1;

-- note: note in the result of each query, the first query found a different liquor store 
-- closer to Best Buy, whereas the second query returned the same coffee shop from your 
-- original search, so you've optimized as much as you can. This demonstrates how spatial
-- joins can help optimize routes by finding intermediate points that reduce total travel.


-- Calculate a New Linestring
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
select st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)')) as linestring from locations;

-- 
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
select st_length(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)'))) 
as length_meters from locations;


-- ============================================================================
-- CREATING POLYGONS: ST_MAKEPOLYGON
-- ============================================================================
-- ST_MAKEPOLYGON() creates a POLYGON from a LINESTRING that forms a closed ring.
-- The LINESTRING must be closed (first point = last point) to form a valid polygon.
-- Polygons represent areas and are useful for defining boundaries, service areas,
-- or regions of interest.

-- Construct a Polygon (st_makepolygon)
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
-- ST_MAKEPOLYGON takes a closed LINESTRING (ring) and creates a POLYGON.
-- The LINESTRING we created earlier already closes back to the starting point,
-- so it forms a valid polygon boundary.
select st_makepolygon(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)'))) as polygon from locations;

-- ============================================================================
-- MEASURING POLYGON PERIMETER: ST_PERIMETER
-- ============================================================================
-- calculate the perimeter
-- ST_PERIMETER() calculates the total length of the boundary of a POLYGON in meters.
-- For a polygon created from a route, this gives you the perimeter distance
-- around the area defined by your route.
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
select st_perimeter(st_makepolygon(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)')))) as perimeter_meters from locations;

-- ============================================================================
-- SPATIAL PREDICATES: ST_WITHIN
-- ============================================================================
-- ST_WITHIN(geom1, geom2) returns TRUE if geom1 is completely inside geom2.
-- This is useful for finding points within polygons, polygons within polygons, etc.
-- Unlike ST_DWITHIN (distance-based), ST_WITHIN checks containment, not proximity.

--Find Shops Inside The Polygon
// Define the outer CTE 'search_area'
-- This CTE creates the polygon search area from our route locations.
-- Nested CTEs allow you to build complex queries step by step.
with search_area as (
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, 
st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
select st_makepolygon(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)'))) as polygon from locations)
-- Find all shops whose coordinates (POINTs) are within the polygon search area
select sh.id,sh.coordinates,sh.name,sh.shop,sh.addr_housenumber,sh.addr_street 
from v_osm_ny_shop sh 
// Join v_osm_ny_shop to the 'search_area' CTE using st_within
-- ST_WITHIN in the JOIN condition creates a spatial join based on containment
-- Only shops inside the polygon will be included in the results
join search_area sa on st_within(sh.coordinates,sa.polygon);

-- ============================================================================
-- GEOMETRY COLLECTIONS: Combining Multiple Geometry Types
-- ============================================================================
-- Construct a single geospatial object that includes both the POLYGON you created 
-- as well as a POINT for every shop inside the POLYGON. This single object is known 
-- as a GEOMETRYCOLLECTION
-- A GEOMETRYCOLLECTION can contain multiple geometries of different types (POINTs,
-- LINESTRINGs, POLYGONs, etc.) in a single object. This is useful for visualizing
-- complex spatial relationships or exporting multiple geometries together.
// Define the outer CTE 'final_plot'
with final_plot as (
// Get the original polygon
(with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, 
st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
select st_makepolygon(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)'))) as polygon from locations)
union all
// Find the shops inside the polygon
(with search_area as (
with locations as (
(select to_geography('POINT(-73.986226 40.755702)') as coordinates, 
0 as distance_meters)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_food_beverages 
where shop = 'coffee' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1)
union all
(select fb.coordinates, 
st_distance(e.coordinates,fb.coordinates) as distance_meters 
from v_osm_ny_shop_electronics e 
join v_osm_ny_shop_food_beverages fb on st_dwithin(e.coordinates,fb.coordinates,1600) 
where e.id = 1428036403 and fb.shop = 'alcohol' 
order by 2 limit 1)
union all
(select coordinates, 
st_distance(coordinates,to_geography('POINT(-73.986226 40.755702)'))::number(6,2) 
as distance_meters 
from v_osm_ny_shop_electronics 
where name = 'Best Buy' and 
st_dwithin(coordinates,st_makepoint(-73.986226, 40.755702),1600) = true 
order by 2 limit 1))
select st_makepolygon(st_makeline(st_collect(coordinates),
to_geography('POINT(-73.986226 40.755702)'))) as polygon from locations)
select sh.coordinates 
from v_osm_ny_shop sh 
join search_area sa on st_within(sh.coordinates,sa.polygon)))
// Collect the polygon and shop points into a geometrycollection
-- ST_COLLECT can combine different geometry types into a GEOMETRYCOLLECTION
-- This creates a single object containing both the polygon and all shop points
select st_collect(polygon) from final_plot;


-- ============================================================================
-- LAB SUMMARY: Key Concepts Covered
-- ============================================================================
-- What we've covered in this lab:

-- 1. SNOWFLAKE INFRASTRUCTURE:
--    - How to acquire a shared database from the Snowflake Marketplace
--    - Understanding warehouses (compute resources) and their configuration
--    - Working with databases, schemas, and tables in Snowflake's architecture

-- 2. GEOGRAPHY DATA TYPE:
--    - The GEOGRAPHY data type, its formats GeoJSON, WKT, EWKT, WKB, and EWKB
--    - How to switch between output formats using ALTER SESSION
--    - Understanding that Snowflake uses spherical geometry (WGS84) by default

-- 3. DATA MANAGEMENT:
--    - How to unload data to Snowflake stages (internal file storage)
--    - How to load data files with geospatial data into tables
--    - Understanding file formats and their role in data loading

-- 4. ACCESSOR FUNCTIONS (Parsers):
--    - ST_X() and ST_Y() to extract longitude and latitude from POINT geometries
--    - These functions only work on POINT geometries, not complex geometries

-- 5. CONSTRUCTOR FUNCTIONS:
--    - TO_GEOGRAPHY() to convert strings (WKT, WKB, GeoJSON) to GEOGRAPHY type
--    - ST_MAKEPOINT() to create POINTs from separate longitude/latitude values
--    - ST_MAKELINE() to create LINESTRINGs from collections of points
--    - ST_MAKEPOLYGON() to create POLYGONs from closed LINESTRINGs

-- 6. TRANSFORMATION FUNCTIONS:
--    - ST_COLLECT() to aggregate multiple geometries into collections (MULTIPOINT, etc.)
--    - Can also create GEOMETRYCOLLECTIONs containing different geometry types

-- 7. MEASUREMENT FUNCTIONS:
--    - ST_DISTANCE() to calculate great-circle distance between geometries (in meters)
--    - ST_LENGTH() to calculate the length of LINESTRINGs (in meters)
--    - ST_PERIMETER() to calculate the perimeter of POLYGONs (in meters)

-- 8. SPATIAL PREDICATE FUNCTIONS (Relational):
--    - ST_DWITHIN() to find geometries within a specified distance (distance-based)
--    - ST_WITHIN() to find geometries completely contained within another (containment-based)
--    - Both can be used in WHERE clauses and JOIN conditions for spatial queries

-- 9. SPATIAL JOINS:
--    - How to join tables based on spatial relationships rather than exact matches
--    - Using spatial predicates in JOIN conditions for efficient spatial queries

-- This lab demonstrates Snowflake's comprehensive geospatial capabilities, which follow
-- OGC standards and provide a powerful platform for spatial analytics in the cloud.



