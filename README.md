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
ttt_boxer_drop_chance                0.33 // The percent chance that a player targeted by the boxer's primary attack will drop their current weapon
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
The Randoman is a detective who is able to buy randomat events, rather than detective items.
\
\
**ConVars**
```cpp
ttt_randoman_banned_randomats        credits,blind,speedrun,blerg,deadchat,lame,choose,randomxn,intensifies,delay,oncemore    // The randomats that are not allowed to appear in the randoman's shop. Separate randomat ids with commas. You can find a randomat's ID by turning one off/on in the randomat ULX menu and coping the word between 'ttt_' and '_enabled' that appears in chat.
ttt_randoman_prevent_auto_randomat   1    // Prevent auto-randomat triggering if there is a randoman at the start of the round.
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
- [Game icons](https://game-icons.net/) for the role icons
- [n Beats](https://www.youtube.com/channel/UCqeNgQLxwkV8TqEyxG_q60Q) for the original yelling sound used with the Boxer's flurry of punches ability
- [Fyxen](https://steamcommunity.com/profiles/76561198810121546/) for the model, texture, animation, and sound modification for the boxing gloves and communist manifesto weapons
- [Benconcan](https://freesound.org/people/Benboncan/sounds/66951/) on FreeSound.org for the Boxer's knockout sound
- [Wikimedia Commons](https://commons.wikimedia.org/wiki/File:Soviet_Anthem_Instrumental_1955.ogg) for the copyright-free Soviet Anthem used for the communist manifesto's conversion sound
