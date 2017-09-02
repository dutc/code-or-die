\echo 'Code or Die Dummy Data'
\echo 'James Powell <james@dontusethiscode.com>'
\set VERBOSITY terse
\set ON_ERROR_STOP true

do language plpgsql $$ declare
    exc_message text;
    exc_context text;
    exc_detail text;
begin

raise notice 'populating schema objects';
do $objects$ begin
	set search_path = objects, names, public;

    with
        homeworld_id as (
            insert into objects.systems default values returning id
        )
        , civilization_id as (
            insert into objects.civilizations (name, homeworld, token)
            values ('Titanus', (select * from homeworld_id), 'tt')
            returning id
        )
        , _0 as (
            insert into names.systems (namer, system, name)
            values (
                (select * from civilization_id),
                (select * from homeworld_id),
                'Titanus Earth'
            )
        )
        , ship_id as (
            insert into objects.ships (shipyard, location, flag)
            values (
                (select * from homeworld_id)
                , (select * from homeworld_id)
                , (select * from civilization_id)
            )
            returning id
        )
    insert into names.ships (namer, ship, name)
    values (
        (select * from civilization_id)
        , (select * from ship_id)
        , 'Explorer 1'
    );

    with
        homeworld_id as (
            insert into objects.systems default values returning id
        )
        , civilization_id as (
            insert into objects.civilizations (name, homeworld, token)
            values ('Colossus', (select * from homeworld_id), 'cc')
            returning id
        )
        , _0 as (
            insert into names.systems (namer, system, name)
            values (
                (select * from civilization_id),
                (select * from homeworld_id),
                'Colossus Major'
            )
        )
        , ship_id as (
            insert into objects.ships (shipyard, location, flag)
            values (
                (select * from homeworld_id)
                , (select * from homeworld_id)
                , (select * from civilization_id)
            )
            returning id
        )
    insert into names.ships (namer, ship, name)
    values (
        (select * from civilization_id)
        , (select * from ship_id)
        , 'Destiny 1'
    );

    with
        homeworld_id as (
            insert into objects.systems default values returning id
        )
        , civilization_id as (
            insert into objects.civilizations (name, homeworld, token)
            values ('Magnifica', (select * from homeworld_id), 'mm')
            returning id
        )
        , _0 as (
            insert into names.systems (namer, system, name)
            values (
                (select * from civilization_id),
                (select * from homeworld_id),
                'Magnifica Prime'
            )
        )
        , ship_id as (
            insert into objects.ships (shipyard, location, flag)
            values (
                (select * from homeworld_id)
                , (select * from homeworld_id)
                , (select * from civilization_id)
            )
            returning id
        )
    insert into names.ships (namer, ship, name)
    values (
        (select * from civilization_id)
        , (select * from ship_id)
        , 'Voyager 1'
    );

    update systems
    set controller = (select id from civilizations where homeworld = 1)
    where id = 1;

    update systems
    set controller = (select id from civilizations where homeworld = 2)
    where id = 2;

    update systems
    set controller = (select id from civilizations where homeworld = 3)
    where id = 3;

    drop table if exists names.civilizations;
    create or replace view names.civilizations as (
        select
            (c1.id - 1) * (select count(*) from objects.civilizations) + (c2.id - 1) + 1 as id
            , c1.id as namer
            , c2.id as civilization
            , c2.name as name
            , tstzrange('-infinity', 'infinity', '[)')::tstzrange as asof
        from objects.civilizations as c1,
             objects.civilizations as c2
    );

end $objects$;

exception when others then
	get stacked diagnostics exc_message = message_text;
    get stacked diagnostics exc_context = pg_exception_context;
    get stacked diagnostics exc_detail = pg_exception_detail;
    raise exception E'\n------\n%\n%\n------\n\nCONTEXT:\n%\n', exc_message, exc_detail, exc_context;
end $$;

begin;
	\echo 'sample queries'

	set search_path = objects, names, public;

	\echo 'objects.civilizations'
    select * from objects.civilizations;
	\echo 'objects.systems'
    select * from objects.systems;
	\echo 'objects.ships'
    select * from objects.ships;

	\echo 'names.civilizations'
    select * from names.civilizations;
	\echo 'names.systems'
    select * from names.systems;
	\echo 'names.ships'
    select * from names.ships;

    \echo 'orders.systems'
    select * from orders.systems;
    \echo 'orders.ships'
    select * from orders.ships;

end;
