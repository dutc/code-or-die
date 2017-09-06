\echo 'Code or Die Database Layout'
\echo 'James Powell <james@dontusethiscode.com>'
\set VERBOSITY terse
\set ON_ERROR_STOP true

do language plpgsql $$ declare
    exc_message text;
    exc_context text;
    exc_detail text;
begin

raise notice 'dropping schemas';
drop schema if exists objects cascade;
drop schema if exists names cascade;
drop schema if exists orders cascade;
drop schema if exists events cascade;

raise notice 'creating schemas';
create schema if not exists objects;
create schema if not exists names;
create schema if not exists orders;
create schema if not exists events;

raise notice 'populating schema objects';
do $objects$ begin
	set search_path = objects, public;

	drop type if exists system_status;
	create type system_status as enum ('active', 'destroyed');

	drop type if exists beam_mode;
	create type beam_mode as enum ('transit', 'repair');

	drop type if exists tuning_params;
	create type tuning_params as (
	    real integer
	    , imag integer
	);

	drop table if exists systems;
	create table if not exists systems (
		id serial primary key
		, status system_status not null default 'active'::system_status
		, mode beam_mode not null default 'transit'::beam_mode
		, controller integer default null
		, production integer default 1 check (production > 0)
		, tuning tuning_params  not null default row(0, 0)::tuning_params
	) with oids;

	drop table if exists routes;
	create table if not exists routes (
		id serial primary key
		, origin integer not null references systems (id)
		, destination integer not null references systems (id)
		, distance integer not null check (distance > 0)
	);

    drop table if exists civilizations;
	create table if not exists civilizations (
		id serial primary key
		, name text not null
		, homeworld integer not null references systems (id)
		, token text not null
	) with oids;

	alter table systems add foreign key (controller) references civilizations (id);

	drop type if exists ship_status;
	create type ship_status as enum ('active', 'destroyed');

	drop table if exists ships;
	create table if not exists ships (
		id serial primary key
		, shipyard integer not null references systems (id)
		, location integer references systems (id)
		, flag integer not null references civilizations (id)
	) with oids;

end $objects$;

raise notice 'populating schema names';
do $names$ begin
	set search_path = names, public;

    drop table if exists civilizations;
    create table if not exists civilizations (
        id serial primary key
        , namer integer not null references objects.civilizations (id)
        , civilization integer not null references objects.civilizations (id)
        , name text not null
    );

    drop table if exists systems;
    create table if not exists systems (
        id serial primary key
        , namer integer not null references objects.civilizations (id)
        , system integer not null references objects.systems (id)
        , name text not null
    );

    drop table if exists ships;
    create table if not exists ships (
        id serial primary key
        , namer integer not null references objects.civilizations (id)
        , ship integer not null references objects.ships (id)
        , name text not null
    );

end $names$;

raise notice 'populating schema orders';
do $orders$ begin
	set search_path = orders, public;

	drop type if exists order_status;
	create type order_status as enum ('pending');

    drop table if exists systems;
    create table if not exists systems (
        id serial primary key
        , system integer not null references objects.systems (id)
        , status order_status not null default 'pending'::order_status
        , payload jsonb not null
    );

    drop table if exists ships;
    create table if not exists ships (
        id serial primary key
        , ship integer not null references objects.ships (id)
        , status order_status not null default 'pending'::order_status
        , payload jsonb not null
    );

end $orders$;

raise notice 'populating schema events';
do $events$ begin

	set search_path = orders, public;
	drop table if exists build;
	create table if not exists build (
		id serial primary key
		, system integer not null references objects.systems (id)
		, owner integer not null references objects.civilizations (id)
		, quantity integer not null check (quantity > 0)
		, time timestamp with time zone not null default now()
	);

	drop table if exists warp;
	create table if not exists warp (
		id serial primary key
		, origin integer not null references objects.systems (id)
		, destination integer not null references objects.systems (id)
		, magnitude integer not null
		, time timestamp with time zone not null default now()
	);

	drop table if exists beam_transit;
	create table if not exists beam_transit (
		id serial primary key
		, ship integer not null references objects.ships (id)
		, origin integer not null references objects.systems (id)
		, destination integer not null references objects.systems (id)
		, tuning objects.tuning_params not null
		, time timestamp with time zone not null default now()
	);

	drop table if exists ftl_transit;
	create table if not exists ftl_transit (
		id serial primary key
		, ship integer not null references objects.ships (id)
		, origin integer not null references objects.systems (id)
		, destination integer not null references objects.systems (id)
		, time timestamp with time zone not null default now()
	);

    drop type if exists transit_type;
	create type transit_type as enum ('beam', 'ftl');

	drop view if exists transit;
	create or replace view transit as (
	    select 'beam_transit'::regclass as type, ship, origin, destination, tuning, time from beam_transit
	    union
	    select 'ftl_transit'::regclass as type, ship, origin, destination, null as tuning, time from ftl_transit
	);

	drop table if exists attack;
	create table if not exists attack (
		id serial primary key
		, ship integer not null references objects.ships (id)
		, time timestamp with time zone not null default now()
	);

end $events$;

exception when others then
	get stacked diagnostics exc_message = message_text;
    get stacked diagnostics exc_context = pg_exception_context;
    get stacked diagnostics exc_detail = pg_exception_detail;
    raise exception E'\n------\n%\n%\n------\n\nCONTEXT:\n%\n', exc_message, exc_detail, exc_context;
end $$;
