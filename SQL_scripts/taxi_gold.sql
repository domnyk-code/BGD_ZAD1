CREATE SCHEMA IF NOT EXISTS bgdgold;

-- Create tables of potentially invalid and suspicious data to analyze later

-- Table of trips with invalid times
DROP TABLE IF EXISTS bgdgold.invalid_times;

CREATE TABLE bgdgold.invalid_times AS
SELECT
	vendor_id,
	pickup_time,
	dropoff_time,
	passenger_count,
	trip_distance,
	ratecode_id,
	store_and_fwd,
	pickup_location,
	dropoff_location,
	payment_type,
	fare_amount,
	extra,
	mta_tax,
	tip_amount,
	tolls_amount,
	improvement_surcharge,
	total_amount, 
	congestion_surcharge
FROM bgdsilver.taxi_cleaned
WHERE EXTRACT(EPOCH FROM (dropoff_time - pickup_time))/60 < 1
OR EXTRACT(EPOCH FROM (dropoff_time - pickup_time))/60 > 600;

-- Table of trips with invalid amount of passengers
DROP TABLE IF EXISTS bgdgold.invalid_passengers;

CREATE TABLE bgdgold.invalid_passengers AS
SELECT
	vendor_id,
	pickup_time,
	dropoff_time,
	passenger_count,
	trip_distance,
	ratecode_id,
	store_and_fwd,
	pickup_location,
	dropoff_location,
	payment_type,
	fare_amount,
	extra,
	mta_tax,
	tip_amount,
	tolls_amount,
	improvement_surcharge,
	total_amount, 
	congestion_surcharge
FROM bgdsilver.taxi_cleaned
WHERE passenger_count IS NULL
OR passenger_count < 1
OR passenger_count > 4;

-- Table of trips with invalid distance
DROP TABLE IF EXISTS bgdgold.invalid_distance;

CREATE TABLE bgdgold.invalid_distance AS
SELECT
	vendor_id,
	pickup_time,
	dropoff_time,
	passenger_count,
	trip_distance,
	ratecode_id,
	store_and_fwd,
	pickup_location,
	dropoff_location,
	payment_type,
	fare_amount,
	extra,
	mta_tax,
	tip_amount,
	tolls_amount,
	improvement_surcharge,
	total_amount, 
	congestion_surcharge
FROM bgdsilver.taxi_cleaned
WHERE trip_distance <= 0;


-- Create tables aggregating data
-- Daily trip summary
DROP TABLE IF EXISTS bgdgold.trip_summary;

CREATE TABLE bgdgold.trip_summary AS
SELECT
	DATE(pickup_time) as trip_date,
	COUNT(*) as total_trips,
	COUNT(DISTINCT vendor_id) as active_vendors,

	-- Passenger metrics
	SUM(passenger_count) as total_passenger,
	ROUND(AVG(passenger_count), 2) as avg_passengers,

	-- Financial metrics
	ROUND(SUM(fare_amount), 2) as total_fares,
	ROUND(SUM(tip_amount), 2) as total_tips,
	ROUND(SUM(tolls_amount), 2) as total_tolls,
	ROUND(SUM(total_amount), 2) as total_revenue,
	ROUND(AVG(fare_amount), 2) as average_fares,

	-- Tip metrics
	SUM(CASE WHEN tip_amount > 0 THEN 1 ELSE 0 END) AS times_tipped,

	-- Distance metrics
	ROUND(AVG(trip_distance), 2) as average_distance
FROM bgdsilver.taxi_cleaned
GROUP BY DATE(pickup_time)
ORDER BY trip_date;

-- Trip summary by vendor
DROP TABLE IF EXISTS bgdgold.vendor_summary;

CREATE TABLE bgdgold.vendor_summary AS
SELECT
-- Add vendor name table possibly
	vendor_id,
	COUNT(*) as total_trips,
	COUNT(DISTINCT DATE(pickup_time)) as days_active,
	ROUND(COUNT(*) / COUNT(DISTINCT DATE(pickup_time)), 2) as avg_trips_daily,

	-- Trip metrics
	ROUND(AVG(trip_distance), 2) as avg_distance,
	ROUND(AVG(passenger_count), 2) as avg_passengers,

	-- Financial metrics
	ROUND(AVG(fare_amount), 2) as avg_fare,
	ROUND(AVG(total_amount), 2) as avg_revenue,
	ROUND(SUM(total_amount) ,2) as total_lifetime_revenue,
	ROUND(SUM(tip_amount), 2) as total_lifetime_tips,
	ROUND(AVG(tip_amount), 2) as avg_tip_per_trip
FROM bgdsilver.taxi_cleaned
GROUP BY vendor_id;

SELECT * FROM bgdgold.invalid_times LIMIT 5;
SELECT * FROM bgdgold.invalid_distance LIMIT 5;
SELECT * FROM bgdgold.invalid_passengers LIMIT 5;

SELECT * FROM bgdgold.trip_summary LIMIT 5;
SELECT * FROM bgdgold.vendor_summary LIMIT 5;
