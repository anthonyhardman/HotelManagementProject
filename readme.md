# Hotel Management Project
## Re-Runnable Creation Script
The re-runnable creation script can be found [here](./creation.sql).

If you would like to create an empty database using our schema and docker you can run the following:
```sh
docker compose up -d
```
The database credentials are ```Database: hotel```, ```Username: hotel```, ```Password: password```.

## Data Generation Documentation
### To generate N number of guest call the following:
```sql
call generate_guests(num integer);
```

### To generate N numbers of staff call the following:
```sql
call generate_staff(num integer);
```

### To generate N number of reservations call the following:
```sql
call generate_reservations(num integer);
```
```* For this call to succeed guests must exist in the guest table```

### To generate one reservation room for every reservation call the following:
```sql
call generate_reservation_rooms();
```

### To generate one rental for every reservation call the following:
```sql
call generate_rentals();
```

### To generate N number of rooms call the following:
```sql
call generate_rooms(num integer);
```
```* For this call to succeed room types must exist in the room type table```

### To generate an occupancy cleaning for every room call the follwoing:
```sql
call generate_cleanings();
```

### To generate one rental room for every rental call the following:
```sql
call generate_rental_rooms();
```

### To generate one rental payment for every rental call the following:
```sql
call generate_rental_payments();
```  

## Key-Feature Proof
The queries that prove our key-features can be found [here](./proof.sql) 