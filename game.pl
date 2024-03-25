/* Prolog "game of thrones" adventure game written by Vladimir Kulikov */
 
/* Debug shortcuts */
clear_all :- 
    retractall(currently_located_in(_)),
    retractall(previously_located_in(_)),
    retractall(player_has(_)),
    retractall(unlocked_door(_)),
    retractall(item_location(_, _)),
    retractall(mob_location(_, _)),
    retractall(player_status(_)),
    retractall(game_status(_)),
    retractall(retreated()),
    retractall(teleport_place(_)),
    retractall(game_started()).

update :- 
    clear_all,
    reconsult("game.pl"), 
    write("Game database updated.\n").


/* Game shortcuts */
help() :-																		
	ansi_format([bold, fg(magenta)],"Game of thrones adventure game controls:\n", []),
	write("start.         ...     Starts the game"), 					                            nl,
	write("n./s./w./e.    ...     Move in that direction (north, south, west, east)"),				nl,
	write("i.             ...     Prints your inventory"), 				                            nl,
    write("t.             ...     Take the item (stores it in the inventory)"), 	                nl,
	write("l.             ...     Prints info about your current location"), 	                    nl,
    write("o.             ...     Unlocks the door"), 	                                            nl,
    write("f.             ...     Fight the mob"), 	                                                nl,
    write("r.             ...     Retreat from the mob"), 	                                        nl,
    write("tp.            ...     Teleport to the location set with 'tps' command"), 	            nl,
    write("tps.           ...     Set the teleport location (where you will be able to teleport)"), nl,
	write("h./help.       ...     Shows this help text"), 				                            nl,
	write("restart.       ...     Restarts the game"), 					                            nl,
	nl, nl.

n :- game_started, move(north).
s :- game_started, move(south).
e :- game_started, move(east).
w :- game_started, move(west).
i :- game_started, inventory().
t :- game_started, take().
l :- game_started, look_around().
o :- game_started, open_door().
f :- game_started, fight().
r :- game_started, retreat().
tp :- game_started, teleport().
tps :- game_started, teleport_set().
h :- game_started, help().
restart :- game_started, update(), start().

/* On start */
:- clear_all, help.

/* Start the game. Set the initial location */
start :- 
    not(game_started),

    /* Facts about items in locations (temporary) */
    assert(item_location(crypt_key, kennels)),
    assert(item_location(armory_key, bell_tower)),
    assert(item_location(steel_sword, armory)),
    assert(item_location(master_key, secret_master_room)),
    assert(item_location(bran_key, secret_bran_room)),
    assert(item_location(silver_sword, broken_tower)),
    assert(item_location(teleport_machine, east_gate)),

    /* Facts about mobs in locations (temporary) */
    assert(mob_location(lannister_killer, library_tower)),
    assert(mob_location(lannister_killer, first_keep)),
    assert(mob_location(white_walker, sept)),
    assert(mob_location(white_walker, godswood)),

    /* Player's health */
    assert(player_status(alive)),  % alive/dead
    assert(game_status(idle)),     % idle/fight

    /* Teleport default place */
    assert(teleport_place(east_gate)),

    /* Others */
    assert(currently_located_in(kitchen)), 
    assert(previously_located_in(kitchen)), 
    assert(game_started),
    location_intro(kitchen).
    


/* Neighbours of the given location */
/* neighbour(+-Location, +-Neighbour) */
neighbour(Location, Neighbour) :- path(Location, _, Neighbour).


/* Play location intro */
location_intro(Location) :- 
    location_describe(Location),
    location_intro_mobs(Location).

location_intro_mobs(Location) :- exists_mob_in_location(Location), location_mobs(Location), !.
location_intro_mobs(Location) :- not(exists_mob_in_location(Location)), location_items(Location), routes(Location), !.
location_intro_items_routes(Location) :- location_items(Location), routes(Location), !.


/* Describe the location */
location_describe(Location) :- description(Location, Desc), write(Desc), nl.

/* Prints info about current location */
look_around :- 
    currently_located_in(CurLocation),
    location_intro(CurLocation).

/* List items that are in the location */
location_items(Location) :- 
    item_location(Item, Location), description(Item, Desc),
    ansi_format([fg(yellow)], "There's the ~w here!\n", [Desc]).

location_items(_) :- true.


/* List mobs that are in the location */
location_mobs(Location) :- 
    mob_location(Mob, Location), description(Mob, Desc),
    ansi_format([fg(red)], "There is ~w in front of you!\n", [Desc]),
    fight_description(Mob, FightDesc),
    ansi_format([fg(red)], "~w\n", [FightDesc]).

exists_mob_in_location(Location) :- mob_location(_, Location), !.


/* Fight mob */
start_fight(Location) :- exists_mob_in_location(Location), retract(game_status(_)), assert(game_status(fight)), !.
start_fight(Location) :- not(exists_mob_in_location(Location)), !.

end_fight() :- retract(game_status(_)), assert(game_status(idle)), !.

fight() :-
    player_status(alive), game_status(fight),
    currently_located_in(CurLocation), mob_location(Mob, CurLocation),
    can_fight(Mob),
    retract(mob_location(Mob, CurLocation)),
    description(Mob, Desc),
    ansi_format([fg(green)], "You've slayed ~w!\n", [Desc]),
    end_fight(),
    location_intro_items_routes(CurLocation),
    !.

/* Failed fighting */
fight() :- 
    player_status(alive), game_status(fight),
    ansi_format([fg(red)], "You can't fight him! (You probably don't have the right sword)\n", []), 
    loose(),
    !.

fight() :- 
    game_status(idle),
    ansi_format([fg(red)], "You can only fight when you meet an enemy!\n", []),
    !.

/* Win the game */
win() :- 
    ansi_format([fg(green)], "Congratulations! You've open the north gate and finally ready to slay the Kind of the night!\nThe end...\n", []),
    clear_all.


/* Loose the game */
loose() :-
    ansi_format([fg(red)], "So, you're dead ;( \n", []),
    retract(player_status(_)), assert(player_status(dead)), clear_all.

/* Fight lannister */
can_fight(lannister_killer) :-
    player_has(steel_sword), !.


/* Fight white walker */
can_fight(white_walker) :-
    player_has(silver_sword), !.


/* Retreat from mob if possible */
retreat() :-
    game_status(fight),
    not(retreated()),
    currently_located_in(CurLocation), mob_location(Mob, CurLocation),
    player_status(alive),
    can_retreat_from(Mob),
    end_fight(),
    description(Mob, Desc),
    assert(retreated()),
    ansi_format([fg(green)], "You've retreated from ~w, next time you won't be able to do this!\n", [Desc]),
    previously_located_in(PrevLocation),
    move_directly(PrevLocation),
    !.

/* Failed to retreat */
retreat() :-
    game_status(fight),
    retreated(), 
    ansi_format([fg(red)], "You've already used your chance to retreat!\n", []),
    loose, 
    !.

retreat() :-
    game_status(fight),
    ansi_format([fg(red)], "You can't retreat!\n", []),
    loose, 
    !.

retreat() :-
    game_status(idle),
    ansi_format([fg(red)], "You can retreat only in a fight!\n", []),
    !.



/* Move directly to the location */
move_directly(Destination) :-
    game_status(idle), player_status(alive),
    currently_located_in(CurLocation),
    retract(previously_located_in(_)), assert(previously_located_in(CurLocation)),
    retract(currently_located_in(_)), assert(currently_located_in(Destination)),
    location_intro(Destination).
    

/* Move to the chosen direction */
move(Direction) :- 
    game_status(idle), player_status(alive),
    currently_located_in(CurLocation), path(CurLocation, Direction, Destination),
    ( not(door(Destination, _)) ; ( door(Destination, _), unlocked_door(Destination) )),
    retract(previously_located_in(_)), assert(previously_located_in(CurLocation)),
    retract(currently_located_in(_)), assert(currently_located_in(Destination)), 
    location_intro(Destination),
    start_fight(Destination),
    !.


/* Failed to move */
move(_) :- 
    (game_status(fight) ; player_status(dead)) ,
    ansi_format([fg(red)],"Player is dead or in fight status!",[]),
    !.

move(Direction) :- 
    currently_located_in(CurLocation), not(path(CurLocation, Direction, _)),
    ansi_format([fg(red)],"There's no such path!",[]),
    !.

move(Direction) :- 
    currently_located_in(CurLocation), path(CurLocation, Direction, Destination),
    door(Destination, _), not(unlocked_door(Destination)),
    ansi_format([fg(red)],"This door is locked, you need first to find a key and then unlock the door!",[]),
    !.


/* Facts - what items player currently has in the inventory */
% player_has(food).


/* Open the door with the key item from the inventory */
open_door :-
    is_any_door_around,
    findall(Item, (player_has(Item), key(Item)) , Keys),
    try_open_with(Keys), 
    !.

open_door :-
    ansi_format([fg(red)], "There are no locked doors around you!\n", []).

open_with(armory_key) :- 
    neighbour(armory, Neighbour), currently_located_in(Neighbour), player_has(armory_key), 
    assert(unlocked_door(armory)), retract(player_has(armory_key)),
    ansi_format([fg(green)], "You have unlocked the Armory!\n", []),
    !.

open_with(crypt_key) :- 
    neighbour(crypt, Neighbour), currently_located_in(Neighbour), player_has(crypt_key), 
    assert(unlocked_door(crypt)), retract(player_has(crypt_key)),
    ansi_format([fg(green)], "You have unlocked the Crypt!\n", []),
    !.

/* Final north gate */
open_with(_) :- 
    currently_located_in(alleyway), 
    player_has(bran_key), 
    player_has(master_key), 
    win(),
    !.

/* Fail to open with the given key */
open_with(_) :- fail.

/* Are there any locked doors? */
is_any_door_around :-
    door(DoorLocation, _), not(unlocked_door(DoorLocation)),
    neighbour(DoorLocation, Neighbour), currently_located_in(Neighbour), !.


/* Given a list of key items, try to open with each one until found one that successfully opened */
/* try_open_with (+ItemLst) */
try_open_with([]) :- ansi_format([fg(red)], "You don't have the appropriate key to unlock this door!\n", []), !.
try_open_with([H|_]) :- open_with(H), !.
try_open_with([H|T]) :- not(open_with(H)), try_open_with(T).


/* Teleport use */
teleport() :-
    player_status(alive), 
    game_status(idle),
    player_has(teleport_machine),
    teleport_place(Destination),
    currently_located_in(CurLocation),
    Destination \= CurLocation,
    ansi_format([fg(green)], "Teleporting...\n", []),
    move_directly(Destination),
    !.

/* Failed to teleport */
teleport() :-
    ansi_format([fg(red)], "Failed to teleport!\n", []).


/* Set teleport place */
teleport_set() :-
    player_status(alive), 
    game_status(idle),
    player_has(teleport_machine),
    currently_located_in(CurLocation),
    retract(teleport_place(_)), assert(teleport_place(CurLocation)),
    ansi_format([fg(green)], "Teleport place was successfully set!\n", []),
    !.

/* Failed to set teleport place */
teleport_set() :-
    ansi_format([fg(red)], "You can't set teleport place right now!\n", []).
    

/* Take item */
take() :- 
    currently_located_in(CurLocation),
    item_location(Item, CurLocation),
    take(Item),
    !.

take() :- 
    ansi_format([fg(red)], "There's nothing to take!\n", []),
    !.

/* take(+Item) */
take(Item) :- 
    player_status(alive),
    game_status(idle),
    not(player_has(Item)),
    item_location(Item, Location),
    currently_located_in(Location),
    assert(player_has(Item)),
    retract(item_location(Item, Location)),
    description(Item, Desc),
    ansi_format([fg(green)], "You've taken the ~w!\n", [Desc]).


/* Prints player's inventory */
inventory() :- 
    not(is_inventory_empty()),
    ansi_format([underline,fg(magenta)], "Inventory:\n", []),
    findall(Item, player_has(Item), Result),
    print_items(Result),
    !.
    
inventory() :- 
    is_inventory_empty(),
    ansi_format([underline,fg(magenta)], "Your inventory is empty!\n", []).

is_inventory_empty() :- not(player_has(_)).


/* Simple predicate to print items (from inventory) */
/* print_items(+ItemList) */
print_items([]) :- !.
print_items([H|T]) :- 
    description(H, Desc),
    ansi_format([fg(magenta)], "-> ~w\n", [Desc]),
    print_items(T).


/* Locked/Unlocked door facts (Doors are locked by default, so they need to have unlocked_door(Door) fact to consider them unlocked) */
door(armory, armory_key).
door(crypt, crypt_key).
door(north_gate, _).
% unlocked_door(_).


/* Prints every possible direction where to go */
/* routes(+Location) */
routes(Location) :- paths(Location).
routes(Location) :- doors(Location).
routes(_) :- true.

/* Specifically paths */
paths(Location) :- path(Location, north, _), write("You can go north."), nl, fail.  
paths(Location) :- path(Location, west, _), write("You can go west."), nl, fail.
paths(Location) :- path(Location, south, _), write("You can go south."), nl, fail.
paths(Location) :- path(Location, east, _), write("You can go east."), nl, fail.

/* Specifically doors (locked/unlocked) */
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, north, Neighbour), not(unlocked_door(Neighbour)), ansi_format([fg(yellow)],"There is a locked door to the north!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, north, Neighbour), unlocked_door(Neighbour), ansi_format([fg(green)],"There is an unlocked door to the north!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, west, Neighbour), not(unlocked_door(Neighbour)), ansi_format([fg(yellow)],"There is a locked door to the west!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, west, Neighbour), unlocked_door(Neighbour), ansi_format([fg(green)],"There is an unlocked door to the west!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, south, Neighbour), not(unlocked_door(Neighbour)), ansi_format([fg(yellow)],"There is a locked door to the south!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, south, Neighbour), unlocked_door(Neighbour), ansi_format([fg(green)],"There is an unlocked door to the south!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, east, Neighbour), not(unlocked_door(Neighbour)), ansi_format([fg(yellow)],"There is a locked door to the east!\n",[]), fail.
doors(Location) :- neighbour(Location, Neighbour), door(Neighbour, _), path(Location, east, Neighbour), unlocked_door(Neighbour), ansi_format([fg(green)],"There is an unlocked door to the east!\n",[]), fail.


/* Path facts of the map */
/* from, direction, to */
path(kitchen, east, outer_yard).
path(kitchen, south, bell_tower).
path(outer_yard, west, kitchen).
path(outer_yard, north, courtyard).
path(outer_yard, south, inner_yard).
path(inner_yard, west, bell_tower).
path(inner_yard, north, outer_yard).
path(inner_yard, east, great_hall).
path(inner_yard, south, south_gate).
path(bell_tower, north, kitchen).
path(bell_tower, east, inner_yard).
path(south_gate, north, inner_yard).
path(courtyard, north, guest_house).
path(courtyard, east, armory).
path(courtyard, south, outer_yard).
path(courtyard, west, library_tower).
path(armory, west, courtyard).
path(armory, east, great_keep).
path(guest_house, south, courtyard).
path(guest_house, west, kennels).
path(kennels, east, guest_house).
path(kennels, west, hunters_gate).
path(hunters_gate, east, kennels).
path(library_tower, east, courtyard).
path(library_tower, west, secret_master_room).
path(secret_master_room, east, library_tower).
path(great_hall, west, inner_yard).
path(great_hall, north, sept).
path(sept, north, great_keep).
path(sept, south, great_hall).
path(great_keep, north, old_pit).
path(great_keep, south, sept).
path(great_keep, west, armory).
path(old_pit, south, great_keep).
path(old_pit, north, first_keep).
path(old_pit, east, east_gate).
path(east_gate, west, old_pit).
path(first_keep, east, broken_tower).
path(first_keep, north, garden).
path(first_keep, west, guards_hall).
path(first_keep, south, old_pit).
path(broken_tower, west, first_keep).
path(garden, south, first_keep).
path(garden, west, crypt).
path(guards_hall, north, crypt).
path(guards_hall, east, first_keep).
path(crypt, east, garden).
path(crypt, south, guards_hall).
path(crypt, west, alleyway).
path(alleyway, north, north_gate).
path(alleyway, west, godswood).
path(alleyway, east, crypt).
path(north_gate, south, alleyway).
path(godswood, east, alleyway).
path(godswood, north, glass_garden).
path(godswood, west, secret_bran_room).
path(secret_bran_room, east, godswood).
path(glass_garden, south, godswood).


/* Location/Room/Item description facts */
description(kitchen, "You've just had dinner Jon Snow, it's time to exit the kitchen and start looking for the keys to the north gate.").
description(outer_yard, "You're in the outer yard. It's suspiciously quiet here...").
description(bell_tower, "You've entered the Bell tower.").
description(inner_yard, "You're in the inner yard.").
description(south_gate, "You're at the South gates. This is a bad sign, south is not for you Jon Snow...").
description(great_hall, "You've entered the Great hall. This is the largest house here, but it seems like there's not a soul here. You hear some weird noises from the Sept, should you go there?").
description(courtyard, "You're in the courtyard.").
description(sept, "You've entered the Sept, you see all buried members of House Stark...").
description(armory, "You've entered armory. You can pick up a steel sword here.").
description(great_keep, "You've entered the Great keep, you can see the whole courtyard from here.").
description(guest_house, "You've entered the Guest house.").
description(kennels, "You're near the kennels.").
description(hunters_gate, "You are at the Hunter's gate.").
description(library_tower, "You've entered the Library tower.").
description(secret_master_room, "You've entered the secret master room. There are so many interesting things out here.").
description(old_pit, "You see the old pit just in front of you.").
description(east_gate, "You're at the East gate.").
description(first_keep, "You've entered the First keep.").
description(broken_tower, "You've entered the Broken tower, place where the most crucial things happen...").
description(garden, "You're in the garden.").
description(crypt, "You've entered the crypt.").
description(guards_hall, "You've entered the Guards hall.").
description(alleyway, "You're standing in the alleyway.").
description(north_gate, "You're just at the North gate. Do you have all necessary keys to open it?").
description(godswood, "You're in the Godswood. Isn't it a good time to pray to the old gods?").
description(glass_garden, "You've entered the glass garden.").
description(secret_bran_room, "You've found the secret bran room! What does he do here?").
description(armory_key, "Armory key").
description(crypt_key, "Crypt key").
description(steel_sword, "Steel sword").
description(master_key, "Master key").
description(bran_key, "Bran key").
description(silver_sword, "Silver sword").
description(lannister_killer, "Lannister's killer").
description(white_walker, "White walker").
description(teleport_machine, "Teleport machine").


/* Other descriptions */
fight_description(lannister_killer, "You can retreat from where you came from, or fight him!").
fight_description(white_walker, "You can't retreat from the white walker, only fight him with your silver sword.").
can_retreat_from(lannister_killer).
key(armory_key).
key(crypt_key).
key(master_key).
key(bran_key).


/* Tests */
test_take_armory_key                :- update, start, s, t, player_has(armory_key), i.
test_die_by_white_walker1           :- update, start, e, s, e, n, r.
test_die_by_white_walker2           :- update, start, e, s, e, n, f.
test_wrong_direction1               :- update, start, e, e.
test_wrong_direction2               :- update, start, e, n, n, n.
test_die_by_lannister_killer1       :- update, start, e, n, w, f.
test_retreat_from_lannister_killer1 :- update, start, e, n, w, r.
test_die_by_lannister_killer2       :- update, start, e, n, w, r, w, r.
test_take_crypt_key                 :- update, start, e, n, n, w, t, i.
test_unlock_armory                  :- update, start, s, t, e, n, n, o.
test_take_teleport                  :- update, start, s, t, e, n, n, o, e, t, e, n, e, t, i.
test_set_teleport_point_and_tp      :- update, start, s, t, e, n, n, o, e, t, e, n, e, t, i, w, n, f, n, tps, s, s, s, w, tp, l.
test_win                            :- update, start, s, t, e, n, n, o, e, t, w, w, f, w, t, e, e, n, w, t, e, s, e, e, n, n, f, e, t, w, w, o, n, w, w, f, w, t, e, e, o.

