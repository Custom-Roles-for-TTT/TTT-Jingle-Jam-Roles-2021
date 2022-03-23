# _Custom Roles for TTT_ Roles Pack for Jingle Jam 2021
A pack of [Custom Roles for TTT](https://github.com/NoxxFlame/TTT-Custom-Roles) roles created based on the generous donations of our community members in support of [Jingle Jam 2021](https://www.jinglejam.co.uk/).

# Roles

## Boxer
_Suggested By_: Fyxen\
The Boxer is a jester role whose goal is to knock out all of the living players.
\
\
**ConVars**
```cpp
ttt_boxer_enabled                    0    // Whether or not the boxer should spawn
ttt_boxer_spawn_weight               1    // The weight assigned to spawning the boxer
ttt_boxer_min_players                0    // The minimum number of players required to spawn the boxer
ttt_boxer_speed_bonus                0.35 // The percent bonus speed a boxer will get while their gloves are out
ttt_boxer_drop_chance                0.33 // The percent chance that a player targeted by the boxer's primary attack will drop their current weapon
ttt_boxer_knockout_chance            0.33 // The percent chance that a player targeted by the boxer's primary attack will get knocked out
ttt_boxer_knockout_duration          10   // The number of a seconds a player targeted by the boxer's secondary attack will be knocked out for
ttt_boxer_hide_when_active           0    // Whether to hide the boxer from other players once the fight has started (e.g. hide from radar, disable icon over head, etc.)
```

## Communist
_Suggested By_: Horselover Fat\
The Communist is an independent role whose goal is to convert all living players to communism using the Communist Manifesto.
\
\
**ConVars**
```cpp
ttt_communist_enabled                0    // Whether or not the communist should spawn
ttt_communist_spawn_weight           1    // The weight assigned to spawning the communist
ttt_communist_min_players            0    // The minimum number of players required to spawn the communist
ttt_communist_convert_time           5    // The amount of time it takes the Communist Manifesto to convert a player
ttt_communist_convert_credits        1    // How many credits to award the non-communists when a player is converted
ttt_communist_convert_freeze         0    // Whether to freeze a player in place while they are being converted
ttt_communist_convert_unfreeze_delay 1    // The number of seconds a player will stay frozen after the conversion process is cancelled
```

## Randoman
_Suggested By_: The Stig\
The Randoman is a detective who is able to buy randomat events, rather than detective items.\
_Requires [TTT Randomat 2.0 for Custom Roles for TTT](https://steamcommunity.com/sharedfiles/filedetails/?id=2055805086) to be installed._
\
\
**ConVars**
```cpp
ttt_randoman_enabled                 0    // Whether or not the randoman should spawn
ttt_randoman_spawn_weight            1    // The weight assigned to spawning the randoman
ttt_randoman_min_players             0    // The minimum number of players required to spawn the randoman
ttt_randoman_banned_randomats        lame // Events not allowed in the randoman's shop, separate ids with commas. You can find an ID by turning a randomat on/off in the randomat ULX menu and copying the word after 'ttt_randomat_', which appears in chat.
ttt_randoman_prevent_auto_randomat   1    // Prevent auto-randomat triggering if there is a randoman at the start of the round.
ttt_randoman_guaranteed_categories   biased_innocent,fun,moderateimpact    // A randomat from these categories is guaranteed be in the randoman's shop, separate categories with commas.
// Categories: biased_innocent, biased_traitor, biased_zombie, biased, deathtrigger, entityspawn, eventtrigger, fun, gamemode, item, largeimpact, moderateimpact, rolechange, smallimpact, spectator, stats
ttt_randoman_guaranteed_randomats    ""   // These events are guaranteed be in the randoman's shop, separate event IDs with commas.
```

## Santa
_Suggested By_: [The Custom Roles for TTT Discord Server](https://discord.gg/BAPZrykC3F) \
Santa is a detective who is able to give gifts to nice players and coal to naughty players.
\
\
**ConVars**
```cpp
ttt_santa_enabled                    0    // Whether or not the santa should spawn
ttt_santa_spawn_weight               1    // The weight assigned to spawning the santa
ttt_santa_min_players                0    // The minimum number of players required to spawn the santa
ttt_santa_random_presents            0    // Whether santa should give random presents instead of being able to choose presents from the shop
ttt_santa_jesters_are_naughty        1    // Whether jesters are considered to be "naughty" players
ttt_santa_independents_are_naughty   0    // Whether independents are considered to be "naughty" players
```

## Taxidermist
_Suggested By_: Horselover Fat\
The Taxidermist is a member of the traitor team whose goal is to use their taxidermy kit on a corpse to make it impossible to identify.
\
\
**ConVars**
```cpp
ttt_taxidermist_enabled              0    // Whether or not the taxidermist should spawn
ttt_taxidermist_spawn_weight         1    // The weight assigned to spawning the taxidermist
ttt_taxidermist_min_players          0    // The minimum number of players required to spawn the taxidermist
ttt_taxidermist_device_time          5    // The number of seconds the taxidermist's device takes to use on a corpse
```

## Special Thanks
- [Benboncan](https://freesound.org/people/Benboncan/sounds/66951/) on FreeSound.org for the Boxer's knockout sound
- [Fyxen](https://steamcommunity.com/profiles/76561198810121546/) for the model, texture, and animations for the boxing gloves and communist manifesto, for sound modification for the boxing gloves, and for the model and texture modifications for the christmas cannon
- [Game icons](https://game-icons.net/) for the role icons
- Kathar for the model and texture for the christmas present
- [n Beats](https://www.youtube.com/channel/UCqeNgQLxwkV8TqEyxG_q60Q) for the original yelling sound used with the Boxer's flurry of punches ability
- [shawshank73](https://freesound.org/people/shawshank73/sounds/119172/) on FreeSound.org for the Boxer's "Fight!" announcement
- [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Soviet_Anthem_Instrumental_1955.ogg) for the copyright-free Soviet Anthem used for the communist manifesto's conversion sound
