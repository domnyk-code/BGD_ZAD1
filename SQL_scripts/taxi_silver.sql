CREATE SCHEMA IF NOT EXISTS bgdsilver;

-- INSERTING DATA INTO THE SILVER LAYER
DROP TABLE IF EXISTS bgdsilver.taxi_cleaned;

CREATE TABLE bgdsilver.taxi_cleaned (
	-- Primary key for record ID
	trip_id BIGSERIAL PRIMARY KEY,

	-- Metadata from bronze layer + silver
	source_file VARCHAR(255),
	load_time_bronze TIMESTAMP,
	load_time_silver TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

	-- Fields from the bronze layer, now with proper typing
	vendor_id INTEGER,
	pickup_time TIMESTAMP,
	dropoff_time TIMESTAMP,
	passenger_count INTEGER,
	trip_distance DECIMAL(10,2),
	ratecode_id INTEGER,
	store_and_fwd CHAR(1),
	pickup_location INTEGER,
	dropoff_location INTEGER,
	payment_type INTEGER,
	fare_amount DECIMAL(10,2),
	extra DECIMAL(10,2),
	mta_tax DECIMAL(10,2),
	tip_amount DECIMAL(10,2),
	tolls_amount DECIMAL(10,2),
	improvement_surcharge DECIMAL(10,2),
	total_amount DECIMAL(10,2), 
	congestion_surcharge DECIMAL(10,2)
);

-- Create Indexes for some common data queries
CREATE INDEX silver_pickup_time_index ON bgdsilver.taxi_cleaned(pickup_time);
CREATE INDEX silver_dropoff_time_index ON bgdsilver.taxi_cleaned(dropoff_time);
CREATE INDEX silver_fare_amount_index ON bgdsilver.taxi_cleaned(fare_amount);
CREATE INDEX silver_trip_distance_index ON bgdsilver.taxi_cleaned(trip_distance);

--Import data from bronze layer
INSERT INTO bgdsilver.taxi_cleaned (
	source_file, load_time_bronze, vendor_id, pickup_time, dropoff_time, passenger_count, 
	trip_distance, ratecode_id, store_and_fwd, pickup_location, dropoff_location, payment_type, 
	fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge, total_amount, congestion_surcharge
)
SELECT
	source_file,
	load_time,
	CAST(vendor_id AS INTEGER),
	CAST(pickup_time AS TIMESTAMP),
	CAST(dropoff_time AS TIMESTAMP),
	CAST(passenger_count AS INTEGER),
	CAST(trip_distance AS DECIMAL(10,2)),
	CAST(ratecode_id AS INTEGER),
	CAST(store_and_fwd AS CHAR(1)),
	CAST(pickup_location AS INTEGER),
	CAST(dropoff_location AS INTEGER),
	CAST(payment_type AS INTEGER),
	CAST(fare_amount AS DECIMAL(10,2)),
	CAST(extra AS DECIMAL(10,2)),
	CAST(mta_tax AS DECIMAL(10,2)),
	CAST(tip_amount AS DECIMAL(10,2)),
	CAST(tolls_amount AS DECIMAL(10,2)),
	CAST(improvement_surcharge AS DECIMAL(10,2)),
	CAST(total_amount AS DECIMAL(10,2)), 
	CAST(congestion_surcharge AS DECIMAL(10,2))
FROM bgdbronze.taxi_raw
WHERE pickup_time IS NOT NULL -- Filter pickup and dropoff times first - since we want to analyze trips we need to have a proper trip date
AND dropoff_time IS NOT NULL
AND pickup_time < dropoff_time;


-- CLEANING DATA
-- Drop records where any of the monetary values are NULL (so as to not interfere with the later equations) 
DELETE FROM bgdsilver.taxi_cleaned WHERE fare_amount IS NULL; -- fare
DELETE FROM bgdsilver.taxi_cleaned WHERE extra IS NULL OR mta_tax IS NULL; -- taxes
DELETE FROM bgdsilver.taxi_cleaned WHERE tip_amount IS NULL OR tolls_amount IS NULL; -- tips and tolls
DELETE FROM bgdsilver.taxi_cleaned WHERE improvement_surcharge IS NULL OR congestion_surcharge IS NULL; -- surcharge

-- Drop records where any of the monetary values are negative
DELETE FROM bgdsilver.taxi_cleaned WHERE fare_amount < 0; -- fare
DELETE FROM bgdsilver.taxi_cleaned WHERE extra < 0 OR mta_tax < 0 ; -- taxes
DELETE FROM bgdsilver.taxi_cleaned WHERE tip_amount < 0 OR tolls_amount < 0; -- tips and tolls
DELETE FROM bgdsilver.taxi_cleaned WHERE improvement_surcharge < 0 OR congestion_surcharge < 0; -- surcharge


-- THIS IS NOW DONE IN GOLD LAYER AS PER SUGGESTIONS
-- -- Replace values where passenger amount is missing or is illegal (no passengers, more than 4 passengers)
-- -- [According to NYC Taxi & Limousine Commission most NY cabs possess 4 passenger seats]
-- UPDATE bgdsilver.taxi_cleaned SET passenger_count = 1 WHERE passenger_count IS NULL;
-- UPDATE bgdsilver.taxi_cleaned SET passenger_count = 1 WHERE passenger_count < 1;
-- UPDATE bgdsilver.taxi_cleaned SET passenger_count = 4 WHERE passenger_count > 4;

-- -- Drop records of impossible trips (eg. travel time less than 1 minute or higher than 10 hours)
-- -- [According to NYC Taxi & Limousine Commission drivers are prohibited from driving more than 10 hours in a single trip]
-- DELETE FROM bgdsilver.taxi_cleaned WHERE EXTRACT(EPOCH FROM (dropoff_time - pickup_time))/60 < 1;
-- DELETE FROM bgdsilver.taxi_cleaned WHERE EXTRACT(EPOCH FROM (dropoff_time - pickup_time))/60 > 600;


-- ADDITIONAL TABLES
-- Create table of zone information for later analysis
DROP TABLE IF EXISTS bgdsilver.zone_lookup;

CREATE TABLE bgdsilver.zone_lookup (
	-- Zone ids and data
	location_id INTEGER PRIMARY KEY,
	borough VARCHAR(255),
	taxi_zone VARCHAR(255),
	service_zone VARCHAR(255)
);

CREATE INDEX silver_borough_index ON bgdsilver.zone_lookup(borough);

-- FILE PATH NEEDS TO BE INSERTED HERE --
-- COPY bgdsilver.zone_lookup
-- FROM ''
-- DELIMITER ','
-- CSV HEADER;



SELECT * FROM bgdsilver.zone_lookup;
SELECT * FROM bgdsilver.taxi_cleaned LIMIT 5;