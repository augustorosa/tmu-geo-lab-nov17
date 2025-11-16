# What's Next: Extending the TMU Geospatial Lab

This guide highlights advanced topics students can explore after finishing `lab.sql`. Each section builds on the foundation from the main lab but dives deeper into Snowflake's geospatial and ML capabilities.

## 1. Advanced GEOGRAPHY Workflows
- **ST_BUFFER + ST_INTERSECTS**: Model catchment areas (e.g., 500 m walk shed) and intersect with other layers to find overlapping amenities.
- **Spatial clustering**: Define clustering keys on frequently filtered columns (e.g., borough, shop type) to improve query performance at scale.
- **H3 grid analysis**: Explore Snowflake's H3 functions to bucket points into hierarchical hex grids for aggregations and visual analytics.

## 2. GEOMETRY-Specific Use Cases
- **Projected coordinate systems**: Recreate the GEOMETRY table with a local SRID (e.g., 2263 for NYC State Plane) and revisit distance/area measurements.
- **ST_TRANSFORM pipelines**: Convert GEOMETRY data between SRIDs to support multi-region analytics or CAD integrations.
- **Engineering-style workflows**: Combine GEOMETRY with building footprints or parcel polygons to perform set difference, buffering, and overlap checks.

## 3. Data Enrichment & Marketplace Integrations
- **Precisely enrichment**: Augment OSM shops with demographics or points of interest using the [Using Precisely to Enrich Data](https://www.snowflake.com/en/developers/guides/using-precisely-enrich-data/) guide.
- **Multi-dataset joins**: Practice joining marketplace datasets (e.g., weather, mobility) via shared spatial keys or proximity queries.

## 4. Machine Learning & Snowpark
- **Geo features for ML**: Follow Snowflake's [Geospatial Data for Machine Learning](https://www.snowflake.com/en/developers/guides/geo-for-machine-learning/) lab to engineer spatial features (distance to POIs, H3 densities) and feed them into Snowpark ML models.
- **Fraud analytics**: Experiment with geo-aware credit-card fraud detection using [Snowflake ML functions](https://www.snowflake.com/en/developers/guides/credit-card-fraud-detection-with-snowflake-ml-functions/), combining transaction coordinates with ST_DWITHIN logic.

## 5. Additional Snowflake Guides
- [Geo Analysis with GEOMETRY](https://www.snowflake.com/en/developers/guides/geo-analysis-geometry/)
- [Geospatial Data for Machine Learning](https://www.snowflake.com/en/developers/guides/geo-for-machine-learning/)
- [Using Precisely to Enrich Data](https://www.snowflake.com/en/developers/guides/using-precisely-enrich-data/)
- [Credit Card Fraud Detection with Snowflake ML Functions](https://www.snowflake.com/en/developers/guides/credit-card-fraud-detection-with-snowflake-ml-functions/)

## Suggested Assignment Flow (≤ 1 hour)
1. Recreate `electronics_geometry` with SRID 2263 and compare ST_DISTANCE vs GEOGRAPHY results.
2. Build a 500 m buffer around Times Square and find all OSM shops within the buffer.
3. Convert results into H3 cells and aggregate counts per resolution.
4. (Optional) Export enriched data to Snowpark Python for feature engineering.

These activities reinforce the main lab and provide a springboard into production-grade Snowflake geospatial solutions.
# Whats