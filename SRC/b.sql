-- for testing only   -- 
-- this will not work -- 
SELECT
	DATE_FORMAT(load_time, '%Y-%m-%d') as date_only,
	DATE_FORMAT(load_time, '%H:%i:%s') as time_only,
	current_l1_user_cnt as l1_count
FROM
	app_market_channel_hourly
WHERE
	load_time BETWEEN ?date_start
	AND ?date_end
	AND ?date_x
	AND ?date_y
	AND ?date_z;