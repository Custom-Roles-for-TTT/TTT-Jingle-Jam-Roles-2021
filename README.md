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
ttt_boxer_speed_bonus                0.35 // The percent bonus speed a boxer will get while their gloves are out
ttt_boxer_drop_chance                0.33 // The percent chance that a player targeted by the boxer's primary attack will drop their current weapon
ttt_boxer_knockout_chance            0.33 // The percent chance that a player targeted by the boxer's primary attack will get knocked out
ttt_boxer_knockout_duration          10   // The number of a seconds a player targeted by the boxer's secondary attack will be knocked out for
```

## Communist
_Suggested By_: Horselover Fat\
The Communist is an independent role whose goal is to convert all living players to communism using the Communist Manifesto.
\
\
**ConVars**
```cpp
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
ttt_randoman_banned_randomats        credits,blind,speedrun,blerg,deadchat,lame,choose,randomxn,intensifies,delay,oncemore    // The randomats that are not allowed to appear in the randoman's shop. Separate randomat ids with commas. You can find a randomat's ID by turning one off/on in the randomat ULX menu and coping the word between 'ttt_' and '_enabled' that appears in chat.
ttt_randoman_prevent_auto_randomat   1    // Prevent auto-randomat triggering if there is a randoman at the start of the round.
```

## Santa
_Suggested By_: [The Custom Roles for TTT Discord Server](https://discord.gg/BAPZrykC3F) \
Santa is a detective who is able to give gifts to nice players and coal to naughty players.
\
\
**ConVars**
```cpp
ttt_santa_random_presents           0   // Whether santa should give random presents instead of being able to choose presents from the shop
ttt_santa_jesters_are_naughty       1   // Whether jesters are considered to be "naughty" players
ttt_santa_independents_are_naughty  0   // Whether independents are considered to be "naughty" players
```

## Taxidermist
_Suggested By_: Horselover Fat\
The Taxidermist is a member of the traitor team whose goal is to use their taxidermy kit on a corpse to make it impossible to identify.
\
\
**ConVars**
```cpp
ttt_taxidermist_device_time          5    // The number of seconds the taxidermist's device takes to use on a corpse
```

## Special Thanks
- [Benboncan](https://freesound.org/people/Benboncan/sounds/66951/) on FreeSound.org for the Boxer's knockout sound
- [Fyxen](https://steamcommunity.com/profiles/76561198810121546/) for the model, texture, and animations for the boxing gloves and communist manifesto, for sound modification for the boxing gloves, and for the model and texture modifications for the christmas cannon
- [Game icons](https://game-icons.net/) for the role icons
- Kathar for the model and texture for the christmas present
- [n Beats](https://www.youtube.com/channel/UCqeNgQLxwkV8TqEyxG_q60Q) for the original yelling sound used with the Boxer's flurry of punches ability
- [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Soviet_Anthem_Instrumental_1955.ogg) for the copyright-free Soviet Anthem used for the communist manifesto's conversion sound