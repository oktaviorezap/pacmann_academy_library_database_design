set search_path to exercise_week8;

-- Create Library_Managers table
create table if not exists library_managers (
    manager_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    phone_number varchar(20) not null unique,
    email varchar(100) not null unique,
    hire_date date not null
);

-- Create Table : Libraries
create table if not exists libraries (
    library_id serial primary key,
    library_name varchar(100) not null unique,
    library_address varchar(255) not null,
    phone_number varchar(20),
    manager_id int not null check(manager_id > 0),
    library_email varchar(100) not null unique,
    library_website varchar(100),
    membership_fee decimal(10, 2) check(membership_fee >= 0),
    library_established_date date,
    constraint fk_manager_lib
    	foreign key(manager_id) references library_managers(manager_id)
);


-- Create Table : Books
create table if not exists books (
    book_id serial primary key,
    title varchar(255) not null,
    author varchar(100) not null,
    category varchar(50) not null check(category in (
        'Self-Improvement', 
        'Biography', 
        'Fantasy', 
        'Romance', 
        'Science Fiction', 
        'History', 
        'Mystery', 
        'Non-Fiction', 
        'Children', 
        'Horror'
    )),
    available_quantity int not null check(available_quantity >= 0), -- Total Book Quantity from all library that restore the Book
    published_date date,
    isbn varchar(20) unique
);


-- Create Table Linking: Library Book Stock 
-- to track book availability in each library
create table if not exists library_book_list (
	library_book_list_id serial primary key,
    library_id int,
    book_id int,
    library_book_quantity int check(library_book_quantity >= 0),
    constraint fk_library_id_list
    	foreign key(library_id) references libraries(library_id),
    constraint fk_book_id_list
    	foreign key(book_id) references books(book_id)
);

-- Create Table : User Registration
create table if not exists user_registration(
    user_id serial primary key,
    first_name varchar(50) not null,
    last_name varchar(50) not null,
    email varchar(100) unique not null,
    registration_date date
);

-- Create Table : Books Borrow (Loan)
create table if not exists books_borrow (
    book_borrow_id serial primary key,
    user_id int check(user_id > 0),
    library_book_list_id int check(library_book_list_id > 0),
    borrow_date date,
    borrow_book_quantity int not null check(borrow_book_quantity > 0),
    books_returned boolean default false, -- if user borrow 2 same books and only 1 returned books_returned is False
    due_date date not null check(due_date = borrow_date + interval '14 days'),
    return_date date,
    constraint fk_user_id_borrow
    	foreign key(user_id) references user_registration(user_id),
	constraint fk_library_book_list_id_borrow
		foreign key(library_book_list_id) references library_book_list(library_book_list_id)
);

-- Create Table : Books Holds
create table if not exists book_holds (
    book_hold_id serial primary key,
    user_id int check(user_id > 0),
    library_book_list_id int check(library_book_list_id > 0),
    book_hold_quantity int not null check(book_hold_quantity > 0),
    hold_date date,
    expiry_date date not null check(expiry_date = hold_date + interval '7 days'),
    is_active boolean default true,
    constraint fk_user_id_holds
    	foreign key(user_id) references user_registration(user_id),
	constraint fk_library_book_list_id_holds
		foreign key(library_book_list_id) references library_book_list(library_book_list_id)
);


-- Input Dummy Data from CSV and Python

-- Input Library Managers Table
copy library_managers(manager_id, first_name, last_name, phone_number, email, hire_date)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\library_managers.csv'
delimiter ','
csv header;

select * from library_managers;

-- Input Libraries Table
copy libraries(library_id, library_name, library_address, phone_number, manager_id, library_email, 
				library_website, membership_fee, library_established_date)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\libraries.csv'
delimiter ','
csv header;

select * from libraries;


-- Input Books Table
copy books(book_id, title, author, category, available_quantity, published_date, isbn)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\books_df.csv'
delimiter ','
csv header;

select * from books;


-- Input Library Book List Table
copy library_book_list(library_book_list_id, library_id, book_id, library_book_quantity)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\library_book_list.csv'
delimiter ','
csv header;

select * from library_book_list;


-- Input User Registration Table
copy user_registration(user_id, first_name, last_name, email, registration_date)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\user_registration.csv'
delimiter ','
csv header;

select * from user_registration;


-- Input Books Borrow Table
copy books_borrow(book_borrow_id, user_id, library_book_list_id, borrow_date, borrow_book_quantity, books_returned, due_date, return_date)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\books_borrow.csv'
delimiter ','
csv header;

select * from books_borrow;


-- Input Books Hold Table
copy book_holds(book_hold_id, user_id, library_book_list_id, book_hold_quantity, hold_date, expiry_date, is_active)
from 'C:\Program Files\PostgreSQL\17\data\File Exercise Week 8 Pacmann Academy\book_holds.csv'
delimiter ','
csv header;

select * from book_holds;

-- 5 Business Question
-- Case 1 : User Registered Numbers in Each Year
select 
	count(user_id),
	extract(year from registration_date) as year
from 
	user_registration
group by
	year;


-- Case 2: Users with Most Active Holds
select 
	t1.user_id,
	user_name,
	email,
	cnt_hold,
	qty_book_hold
from 
	(select 
		user_id,
		count(book_hold_id) as cnt_hold,
		sum(book_hold_quantity) as qty_book_hold
	from 
		book_holds
	group by
		user_id
	order by
		qty_book_hold desc) t1
join 
	(
		select
			user_id,
			concat(first_name,'',last_name) as user_name,
			email
		from
			user_registration
	) t2
on
	t1.user_id = t2.user_id
limit 5;


-- Case 3:Most Frequently Borrowed Books
select 
	t1.user_id,
	user_name,
	email,
	cnt_borrow,
	qty_book_borrow
from 
	(select 
		user_id,
		count(book_borrow_id) as cnt_borrow,
		sum(borrow_book_quantity) as qty_book_borrow
	from 
		books_borrow
	group by
		user_id
	order by
		qty_book_borrow desc) t1
join 
	(
		select
			user_id,
			concat(first_name,'',last_name) as user_name,
			email
		from
			user_registration
	) t2
on
	t1.user_id = t2.user_id
limit 5;


-- Case 4: Identify First Borrow and Last Borrow Books by Users
with 
	final_borrow
as 
	(
		with 
			first_last_borrow	
		as
			(
				select 
					user_id,
					first_value(borrow_date) over(partition by user_id order by borrow_date asc) as first_borrow_date,
					first_value(borrow_date) over(partition by user_id order by borrow_date desc) as last_borrow_date
				from 
					books_borrow
			)
	select
		user_id,
		first_borrow_date,
		last_borrow_date,
		last_borrow_date - first_borrow_date as borrow_first_last_day_diff
	from 
		first_last_borrow
	)
select
	distinct user_id,
	first_borrow_date,
	last_borrow_date,
	borrow_first_last_day_diff
from 
	final_borrow
where 
	borrow_first_last_day_diff > 0
order by
	borrow_first_last_day_diff desc;
	

-- Case 5: Most Borrowed Books in the Library 
with
	most_borrow_books
as
	(
		select 
			*
		from 
			(
				select 
					library_book_list_id,
					sum(borrow_book_quantity) as borrows_qty
				from 
					books_borrow
				group by
					library_book_list_id
			) t1
		join 
			(
				select
					library_book_list_id,
					book_id
				from
					library_book_list
			) t2
		using
			(library_book_list_id)
		order by
			borrows_qty desc
	)
select 
	book_id,
	title,
	author,
	category,
	borrows_qty
from 
	most_borrow_books mbs
join
	books b
using
	(book_id);