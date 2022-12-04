-- Feature: Multiple Room Types --     
	insert into room_type values(1, 'Room Type 1', 100.00, false); --(Id, Room Type, Base Rental Rate, Smoking)
	insert into room_type values(2, 'Room Type 2', 200.00, false);
	select * from room_type rt;
	--|id |r_type     |base_rental_rate|smoking|
	--|---|-----------|----------------|-------|
	--|1  |Room Type 1|100             |false  |
	--|2  |Room Type 2|200             |false  |



-- Feature: Rooms Are Not Oversold -- 
	insert into room values(1, 1, 1); --(Id, Room Number, Room Type Id)
	insert into room values(2, 2, 1);
	insert into room values(3, 3, 1);
	insert into room values(4, 4, 1);
	select * from get_room_types_availability_on_date('2022-3-1');
	--|room_type_id|room_count|available|reserved|  
	--|------------|----------|---------|--------|
	--|1           |4         |4        |0       |
	--|2           |0         |0        |0       |
	
	insert into guest values(1, 'Anthony', 'Hardman');            --(Id, First Name, Last Name)
	insert into reservation values(1, 1, '2022-3-1', '2022-3-2'); --(Id, Guest Id, Expected Checkin, Expected Checkout)
	insert into reservation_room values(1, 1, 1);                 --(Id, Reservation Id, Room Type Id)
	select * from get_room_types_availability_on_date('2022-3-1');
	--|room_type_id|room_count|available|reserved|
	--|------------|----------|---------|--------|
	--|1           |4         |3        |1       |
	--|2           |0         |0        |0       |
	
	insert into guest values(2, 'Breanna', 'Nesbit'); 
	insert into reservation values(2, 2, '2022-3-1', '2022-3-2'); 
	insert into reservation_room values(2, 2, 1);
	select * from get_room_types_availability_on_date('2022-3-1');
	--|room_type_id|room_count|available|reserved|
	--|------------|----------|---------|--------|
	--|1           |4         |2        |2       |
	--|2           |0         |0        |0       |
	
	
	insert into guest values(3, 'Heber', 'Allen'); 
	insert into reservation values(3, 3, '2022-3-1', '2022-3-2'); 
	insert into reservation_room values(3, 3, 1);
	select * from get_room_types_availability_on_date('2022-3-1');
	--|room_type_id|room_count|available|reserved|
	--|------------|----------|---------|--------|
	--|1           |4         |1        |3       |
	--|2           |0         |0        |0       |
	
	
	insert into guest values(4, 'John', 'Doe'); 
	insert into reservation values(4, 4, '2022-3-1', '2022-3-2'); 
	insert into reservation_room values(4, 4, 1);
	select * from get_room_types_availability_on_date('2022-3-1');
	--|room_type_id|room_count|available|reserved|
	--|------------|----------|---------|--------|
	--|1           |4         |0        |4       |
	--|2           |0         |0        |0       |
	
	
	insert into guest values(5, 'Mister', 'Noroom'); 
	insert into reservation values(5, 5, '2022-3-1', '2022-3-2'); 
	insert into reservation_room values(5, 5, 1);
	select * from get_room_types_availability_on_date('2022-3-1');
	--SQL Error [23514]: ERROR: new row for relation "reservation_room" violates check constraint "reservation_room_check"
	--  Detail: Failing row contains (5, 5, 1).



-- Feature: Room Occupancy Preparation --
	insert into staff values(1, 'Mister', 'Clean');
	
	-- Successful Room Assignment
	insert into room_cleaning values(1, '2022-2-28', 1, 1, 1); --(Id, Date Cleaned, Cleaning Type Id, Room Id, Staff Id)
	insert into rental values(1, 1, 1, 1, '2022-3-1', null);   --(Id, Reservation Id, Staff Id, Guest Id, Checkin, Checkout)
	insert into rental_room values(1, 1, 1, 1000.00);          --(Id, Rental Id, Room Cleaning Id, Rental Rate)
	select * from rental_room;
	--|id |rental_id|room_cleaning_id|rental_rate|
	--|---|---------|----------------|-----------|
	--|1  |1        |1               |1,000      |
	
	-- Unsuccessful Room Assignment: Wrong Cleaning Type
	insert into room_cleaning values(2, '2022-2-28', 2, 2, 1); 
	insert into rental values(2, 2, 1, 2, '2022-3-1', null);   
	insert into rental_room values(2, 2, 2, 1000.00);  
	--SQL Error [23514]: ERROR: new row for relation "rental_room" violates check constraint "rental_room_room_cleaning_id_check"
	--  Detail: Failing row contains (2, 2, 2, 1000.00).
	
	-- Unsuccessful Room Assignment: Duplicate Occupancy Cleaning
	insert into rental values(3, 3, 1, 3, '2022-3-1', null);   
	insert into rental_room values(3, 3, 1, 1000.00);          
	--SQL Error [23505]: ERROR: duplicate key value violates unique constraint "rental_room_room_cleaning_id_key"
	--  Detail: Key (room_cleaning_id)=(1) already exists.



-- Feature: Reservation and Rentals --
	-- A reservation is for a room type
	select * from reservation_room rr
	--|id |reservation_id|room_type_id|
	--|---|--------------|------------|
	--|1  |1             |1           |
	--|2  |2             |1           |
	--|3  |3             |1           |
	--|4  |4             |1           |

	-- A rental is for a specific room
	select 	rr.id as "rental_room_id", rr.rental_id, r.room_number
	from	rental_room rr inner join
			room_cleaning rc on (rc.id = rr.room_cleaning_id) inner join 
			room r on (r.id = rc.room_id);
	--|rental_room_id|rental_id|room_number|
	--|--------------|---------|-----------|
	--|1             |1        |1          |

		
-- Feature: Room Cleaning Records --
	-- The staff member who performed a room cleaning must be recored.
	select  rc.id, rc.date_cleaned, s.first_name || ' ' || s.last_name as "staff", ct."type" as "cleaning_type"
	from	room_cleaning rc inner join
			staff s on (s.id = rc.staff_id) inner join 
			cleaning_type ct on (ct.id = rc.cleaning_type_id);
	--|id |date_cleaned|staff       |cleaning_type        |
	--|---|------------|------------|---------------------|
	--|1  |2022-02-28  |Mister Clean|prepare for occupancy|
	--|2  |2022-02-28  |Mister Clean|daily cleaning       |

-- Feature: Room Service Charges --
	insert into room_service_item values
	(1, 'Item 1', 1.00), -- (Id, Item Name, Current Cost)
	(2, 'Item 2', 2.00),
	(3, 'Item 3', 3.00);
	
	insert into room_service_charge values(1, 1, 'Charge 1');
	insert into room_service_charnge_item values
	(1, 1, 1, 1, 1.00), --(Id, Room Service Charge Id, Room Servive Item Id, Quantity, Actual Cost)
	(2, 1, 1, 2, 2.00),
	(3, 1, 1, 3, 3.00);
	
	select * from room_service_charge_info;
	select * from room_service_charge_info;
	--|charge_id|rental_id|room_number|decription|item_name|quanity|actual_cost|total_cost|
	--|---------|---------|-----------|----------|---------|-------|-----------|----------|
	--|1        |1        |1          |Charge 1  |Item 1   |1      |1          |1         |
	--|1        |1        |1          |Charge 1  |Item 2   |2      |2          |4         |
	--|1        |1        |1          |Charge 1  |Item 3   |3      |3          |9         |