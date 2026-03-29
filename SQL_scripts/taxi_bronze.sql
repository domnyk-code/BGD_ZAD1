CREATE SCHEMA IF NOT EXISTS bgdbronze;

-- SELECT schema_name FROM information_schema.schemata;

DROP TABLE IF EXISTS bgdbronze.taxi_raw;

CREATE TABLE bgdbronze.taxi_raw (
	-- Simple metadata
	source_file VARCHAR(255),
	load_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

	-- Fields from the csv file - using VARCHAR in bronze layer and converting later.
	vendor_id VARCHAR(100),
	pickup_time VARCHAR(100),
	dropoff_time VARCHAR(100),
	passenger_count VARCHAR(100),
	trip_distance VARCHAR(100),
	ratecode_id VARCHAR(100),
	store_and_fwd VARCHAR(100),
	pickup_location VARCHAR(100),
	dropoff_location VARCHAR(100),
	payment_type VARCHAR(100),
	fare_amount VARCHAR(100),
	extra VARCHAR(100),
	mta_tax VARCHAR(100),
	tip_amount VARCHAR(100),
	tolls_amount VARCHAR(100),
	improvement_surcharge VARCHAR(100),
	total_amount VARCHAR(100), 
	congestion_surcharge VARCHAR(100)
);

DROP TABLE IF EXISTS taxi_input;

CREATE TEMPORARY TABLE taxi_input (LIKE bgdbronze.taxi_raw);
ALTER TABLE taxi_input DROP COLUMN source_file, DROP COLUMN load_time;

-- FILE PATH NEEDS TO BE INSERTED HERE --
COPY taxi_input
FROM ''
DELIMITER ','
CSV HEADER;

INSERT INTO bgdbronze.taxi_raw (source_file, vendor_id, pickup_time, dropoff_time, passenger_count, trip_distance, ratecode_id, store_and_fwd, pickup_location, dropoff_location, payment_type, fare_amount, extra, mta_tax, tip_amount, tolls_amount, improvement_surcharge, total_amount, congestion_surcharge)
SELECT 'yellow_tripdata_2020-05.csv', * FROM taxi_input;

SELECT * FROM bgdbronze.taxi_raw LIMIT 5;
