# Adventure Game in Prolog

This project is a text-based adventure game inspired by "Game of Thrones," written in Prolog. It actively utilizes the concept of logical programming in a declarative style.

The game offers the following features:

* Nearly 30 unique locations (rooms) interconnected by paths (refer to the graph below).

* A player's inventory for storing collected game items.

* Locked doors that can only be unlocked with special keys.

* Two types of enemies that require specific weapons to defeat.

* Two combat modes against enemies - retreat and fight, varying with the enemy type, which determines the mode of combat.

* Accordingly, there are two types of weapons.

* Teleports, represented as special (collectible) items in the inventory. Additionally, you can place a teleport point at any location on the map.

* Several winning strategies, allowing for different paths to victory.

---

The whole code is richly documented, at the end you can find several tests (similar to unit tests in an imperative language).

---

> Initial inspiration.
<p align="center">
  <img src="https://user-images.githubusercontent.com/111417661/208980081-196f7aee-b827-42c8-845c-13bfa8de3dcb.jpg" />
</p>

> Map to help while playing.
<p align="center">
  <img src="https://user-images.githubusercontent.com/111417661/208979899-73984b73-6521-4601-9f5f-6cb6354c4e74.jpg" />
</p>

> Map with spoilers.
<p align="center">
  <img src="https://user-images.githubusercontent.com/111417661/208980025-64a3211b-6644-4871-9ce8-21b8cbac2264.jpg" />
</p>



## Example usage

To run the game in prolog, simply type:
```bash
swipl
consult("play.pl").
```

Then you will see a helper window with all the shortcuts the player should use:
```
start.         ...     Starts the game
n./s./w./e.    ...     Move in that direction (north, south, west, east)
i.             ...     Prints your inventory
t.             ...     Take the item (stores it in the inventory)
l.             ...     Prints info about your current location
o.             ...     Unlocks the door
f.             ...     Fight the mob
r.             ...     Retreat from the mob
tp.            ...     Teleport to the location set with 'tps' command
tps.           ...     Set the teleport location (where you will be able to teleport)
h./help.       ...     Shows this help text
restart.       ...     Restarts the game
```

For example, here's a combination that sends you to the location where the teleportation item is located, then you take this item and look through your inventory.
```
start, s, t, e, n, n, o, e, t, e, n, e, t, i.
```

You will find all such combinations at the end of the file "game.pl".
