set search_path to public;
drop schema if exists hotel_test cascade;
create schema hotel;
set search_path to hotel;

create table room_type (
    id serial primary key,
    r_type text not null,
    base_rental_rate decimal not null,
    smoking bool not null,
		unique (r_type, smoking)
);

create table room (
    id serial primary key,
    room_number int not null,
    room_type_id int not null references room_type(id)
);

create table guest (
    id serial primary key,
    first_name varchar not null,
    last_name varchar not null
);

create table reservation (
    id serial primary key,
    guest_id int not null references guest(id),
    expected_checkin date not null,
    expected_checkout date not null
);

create or replace function get_room_type_counts()
returns table (room_type_id int, room_type_count bigint)
language plpgsql
as $$
begin
    return query (
    select r.id, count(r2.room_type_id) 
    from    room_type r left join 
            room r2 on (r.id = r2.room_type_id)
    group by r.id
    order by r.id 
    );
end;
$$;

create or replace function get_room_types_availability_on_date(the_date date)
returns table (room_type_id int, room_count bigint, available bigint, reserved bigint)
language plpgsql
as $$
begin
    return query (
    select  rtc.room_type_id, rtc.room_type_count, rtc.room_type_count - count(rr.room_type_id), count(rr.room_type_id)
    from        reservation r inner join
                reservation_room rr on (r.id = rr.reservation_id and the_date >= r.expected_checkin and the_date <= r.expected_checkout) right join 
                get_room_type_counts() rtc on (rtc.room_type_id = rr.room_type_id)
    group by    rtc.room_type_id, rtc.room_type_count
    order by    rtc.room_type_id
    );
end;
$$;

create or replace function room_available(reservation_id int, room_type int) 
returns bool
language plpgsql
as $$
	declare
		reservation record;
		current_check date;
		room_count int;
	begin 
		select * from reservation r where reservation_id = r.id into reservation;
		current_check = reservation.expected_checkin;
		loop
			select 	a.available 
			from 	get_room_types_availability_on_date(current_check) a
			where 	a.room_type_id = room_type into room_count;
		    if room_count = 0 then
		    	return false;
		   	end if;
		   	current_check = current_check + 1;
		    EXIT WHEN current_check > reservation.expected_checkout;
		END LOOP;
		return true;
	end;
$$;

create table reservation_room (
    id serial primary key,
    reservation_id int not null references reservation(id),
    room_type_id int not null references room_type(id),
    check(room_available(reservation_id, room_type_id))
);

create table staff (
    id serial primary key,
    first_name text not null,
    last_name text not null
);

create table rental (
    id serial primary key,
    reservation_id int null references reservation(id),
    staff_id int not null references staff(id),
    guest_id int not null references guest(id),
    checkin date not null,
    checkout date null
);

create table room_service_item (
    id serial primary key,
    item_name text not null,
    current_cost decimal not null
);

create table cleaning_type (
    id serial primary key,
    type text not null
);

create table room_cleaning (
    id serial primary key,
    date_cleaned date not null,
    cleaning_type_id int not null references cleaning_type(id),
    room_id int not null references room(id),
    staff_id int not null references staff(id)
);

create or replace function is_occupancy_cleaning(room_cleaning_id int) returns bool
language plpgsql
as $$
	declare
		cleaning record;
	begin
		select * into cleaning 
		from room_cleaning rc 
		where rc.id = room_cleaning_id;
		return (cleaning.cleaning_type_id = 1);
	end;
$$;

create table rental_room (
    id serial primary key,
    rental_id int not null references rental(id),
    room_cleaning_id int not null references room_cleaning(id)
    check(is_occupancy_cleaning(room_cleaning_id)),
    rental_rate decimal not null,
		unique(room_cleaning_id)
);

create table room_service_charge (
    id serial primary key,
    rental_room_id int not null references rental_room(id),
    decription varchar 
);

create table room_service_charnge_item (
	id serial primary key,
	room_service_charge_id int not null references room_service_charge(id),
	room_service_item_id int not null references room_service_item(id),
	quanity int not null,
	actual_cost int not null
);

create table rental_payment (
    id serial primary key,
    rental_id int not null references rental(id),
    amount decimal not null,
    payment_date date not null
);

create or replace view room_cleaning_info as
select	rc.id as room_id, r.room_number, rt.r_type as room_type, s.first_name || ' ' || s.last_name as staff, 
	    rc.date_cleaned
from	room_cleaning rc inner join
		staff s on (s.id = rc.staff_id) inner join
		room r ON (r.id = rc.room_id) inner join 
		room_type rt on (rt.id = r.room_type_id)
order by rc.id;

create or replace view room_service_charge_info as
select 	r.id as "charge_id", r.id as "rental_id", r2.room_number, rsc.decription, rsi.item_name, rsci.quanity, rsci.actual_cost, 
		rsci.quanity * rsci.actual_cost as "total_cost"
from 	rental r inner join 
		rental_room rr on (rr.rental_id = r.id) inner join
		room_service_charge rsc on (rsc.rental_room_id = rr.id) inner join 
		room_service_charnge_item rsci on (rsci.room_service_charge_id = rsc.id) inner join
		room_service_item rsi on (rsi.id = rsci.room_service_item_id) inner join 
		room_cleaning rc on (rc.id = rr.room_cleaning_id) inner join 
		room r2 on (r2.id = rc.room_id);

-- Data Generation Tools
create or replace function generate_first_name() returns varchar
language plpgsql
as $$
	declare 
		firstnames varchar[];
		firstnames_length int;
	begin
		firstnames := array ['Adam','Bill','Bob','Calvin','Donald','Dwight','Frank','Fred','George','Howard',
    	'James','John','Jacob','Jack','Martin','Matthew','Max','Michael',
    	'Paul','Peter','Phil','Roland','Ronald','Samuel','Steve','Theo','Warren','William',
    	'Abigail','Alice','Allison','Amanda','Anne','Barbara','Betty','Carol','Cleo','Donna',
    	'Jane','Jennifer','Julie','Martha','Mary','Melissa','Patty','Sarah','Simone','Susan'];
    	firstnames_length := (SELECT array_length(firstnames, 1 ));
    	return firstnames[(select random() * (firstnames_length - 1) + 1)];
	end;
$$;

create or replace  function generate_last_name() returns varchar
language plpgsql
as $$
	declare 
		lastnames varchar[];
		lastnames_length int;
	begin
		lastnames := ARRAY['Matthews','Smith','Jones','Davis','Jacobson','Williams','Donaldson','Maxwell','Peterson','Stevens',
	    'Franklin','Washington','Jefferson','Adams','Jackson','Johnson','Lincoln','Grant','Fillmore','Harding','Taft',
	    'Truman','Nixon','Ford','Carter','Reagan','Bush','Clinton','Hancock'];
	   	lastnames_length := (SELECT array_length(lastnames, 1 ));
	   	return lastnames[(select random() * (lastnames_length - 1) + 1)];
	end;
$$;

create or replace procedure generate_guests(num integer)
language plpgsql
as $$
	begin 
		for i in 1..num loop 
			insert into guest values(i, generate_first_name(), generate_last_name());
		end loop;
	end;
$$;

create or replace procedure generate_staff(num integer)
language plpgsql
as $$
	begin 
		for i in 1..num loop 
			insert into staff values(i, generate_first_name(), generate_last_name());
		end loop;
	end;
$$;

create or replace procedure generate_reservations(num integer)
language  plpgsql
as $$
	declare 
		guest_count bigint;
	begin 
		guest_count := (select count(*) from guest);
		for i in 1..num loop
			insert into reservation values (i, (select random() * (guest_count - 1) + 1), current_date, current_date  + (select random() * 14 + 1)::int);
		end loop;
	end;
$$;

create or replace procedure generate_reservation_rooms()
language plpgsql
as $$
	declare 
		reservation record;
		room_type_count bigint;
	begin
		room_type_count = (select count(*) from room_type);
		for reservation in select * from reservation loop
			insert into reservation_room values(reservation.id, reservation.id, (select random() * (room_type_count -1) + 1));
		end loop;
	end;
$$;

create or replace procedure generate_rentals()
language plpgsql
as $$
	declare
	reservation record;
	staff_count bigint;
	begin
		staff_count := (select count(*) from staff);
		for reservation in select * from reservation loop
			insert into rental values(reservation.id, reservation.id, (select random() * (staff_count -1) + 1), reservation.guest_id, 
			reservation.expected_checkin, reservation.expected_checkout);
		end loop;
	end;
$$;

create or replace procedure generate_rooms(num integer) 
language plpgsql
as $$
declare
  room_type_num bigint;
  room_type_id bigint;
begin
  room_type_num := (select count(*) from room_type rt);
  for i in 1..num loop 
    insert into room values 
    (i, i % 20 + (i / 20) * 100, (select random() * (room_type_num-1)+1));
    
  end loop;
end;
$$;

create or replace procedure generate_cleanings()
language plpgsql
as $$
	declare 
		room record;
		staff_count bigint;
	begin 
		staff_count := (select count(*) from staff);
		for room in select * from room loop
			insert into room_cleaning values(room.id, current_date, 1, room.id, (select random() * (staff_count -1) + 1));
		end loop;
	end;
$$;

create or replace function get_prepared_room_cleanings_of_room_type(room_type_id_ int)
returns table (room_cleaning_id int)
language plpgsql
as $$
	begin
		return query (
		select  rc.id  
		from 	room_cleaning rc inner join
				room r on (r.id = rc.room_id and r.room_type_id = room_type_id_)
		where 	not exists (
				select 
				from rental_room rr 
				where rr.room_cleaning_id = rc.id) 
				and rc.cleaning_type_id = 1
		);
	end;
$$;

create or replace function get_reservation_rooms_types_for_rental(rental_id_ int)
returns table (room_type_id int)
language plpgsql
as $$
	begin
		return query (
			select  rr.room_type_id
			from	rental r inner join
					reservation res on (res.id = r.reservation_id) inner join
					reservation_room rr on (rr.reservation_id = res.id)
			where 	r.id = rental_id_
		);
	end;
$$;

create or replace procedure generate_rental_rooms()
language plpgsql
as $$
	declare
		rental record;
		room_type_id int;
		room_cleaning_id int;
		loop_count int := 1;
	begin 
		for rental in select * from rental r loop
			for room_type_id in select * from get_reservation_rooms_types_for_rental(rental.id) loop
				select * into room_cleaning_id 
				from get_prepared_room_cleanings_of_room_type(room_type_id);
				insert into rental_room values(loop_count, rental.id, room_cleaning_id, 100);
				loop_count = loop_count + 1;
			end loop;
		end loop;
	end;
$$;

create or replace procedure generate_rental_payments()
language plpgsql
as $$
	declare 
		rental record;
	begin 
		for rental in select * from rental loop
			insert into rental_payment values(rental.id, rental.id, 100, rental.checkin);
		end loop;
	end
$$;

create or replace procedure generate_chain_1()
language plpgsql
as $$
  begin
    insert into room_type values
    (1, 'Double bed', 300.5, false),
    (2, 'King bed', 500, false),
    (3, 'double-double bed', 150.5, false),
    (4, 'executive suite', 1000.78, false),
    (5, 'super awesome room type', 10000.0, true),
    (6, 'this room type has no rooms', 3200.0, true);
    call generate_guests(200000);
    call generate_reservations(200000);
    call generate_reservation_rooms();
    call generate_rooms(200000);
  end;
$$;

create or replace procedure generate_chain_2()
language plpgsql
as $$
  begin
    insert into cleaning_type values
    (1, 'prepare for occupancy'),
    (2, 'daily cleaning');
    call generate_staff(200000);
    call generate_cleanings();
  end;
$$;

insert into cleaning_type values
(1, 'prepare for occupancy'),
(2, 'daily cleaning');