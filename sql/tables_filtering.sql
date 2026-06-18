/* Data string postgres://Test:bQNxVzJL4g6u@ep-noisy-flower-846766.us-east-2.aws.neon.tech/TravelTide */

/* Filtering of sessions table */
with active_users as
    (select user_id, count(session_id) as total_session from sessions where session_start >= '2023-01-05' group by user_id having count(session_id) > 7)

select * from sessions where sessions.session_start >= '2023-01-05' and sessions.user_id in (select user_id from active_users);


/* Filtering of users table */
with active_users as
    (select user_id, count(session_id) as total_session from sessions where session_start >= '2023-01-05' group by user_id having count(session_id) > 7)

select * from users where users.user_id in (select user_id from active_users);


/* Filtering of flights table */

with active_users as
    (select user_id, count(session_id) as total_session from sessions where session_start >= '2023-01-05' group by user_id having count(session_id) > 7),
valid_trip_id as
   (select sessions.trip_id from sessions where sessions.session_start >= '2023-01-05' and sessions.user_id in (select user_id from active_users))

select * from flights where flights.trip_id in (select trip_id from valid_trip_id);

/* Filtering of hotels table */

with active_users as
    (select user_id, count(session_id) as total_session from sessions where session_start >= '2023-01-05' group by user_id having count(session_id) > 7),
valid_trip_id as
   (select sessions.trip_id from sessions where sessions.session_start >= '2023-01-05' and sessions.user_id in (select user_id from active_users))

select * from hotels where hotels.trip_id in (select trip_id from valid_trip_id);







