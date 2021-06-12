# ARrehab
AR rehabilitation app designed for UCSF children's hospital.
This is a research project done under the advisement of Professor Allen Yang and Kat Quigley.

## Instructions
1. When app loads, move your camera slowly to scan your environment. (Make sure to scan a horizontal plane)
2. An invisible game board will show up with two buttons. Walk on the tiles as they light up to create a game board path.
3. Once the game board lights up green, click "Place Board"
4. A game board will show up with two types of minigames indicated by a M (the Squat game) and a bear (the Laser game). Walk to the minigame of your choice to start the game.
5. To toggle on or off the minigame, toggle on or off the switch at the top.

## Installation
1. Launch Terminal (You can find this via Spotlight)
2. Clone the repository `git clone https://github.com/augcog/AR-Health.git`
3. Switch to the Minigames branch. `git checkout minigames`
4. From finder, launch the project (Double click `AR-Health/ARrehab/ARrehab.xcodeproj`). You can also launch from XCode
5. Change the signing certificate to your own Apple Developer account.
    1. In the File heirarchy on the left panel, select the blue Xcode project icon (root of the heirarchy).
    2. In the main center editor on the top left there is a drop down, select ARrehab (the icon should be an `A` made of brushes)
    3. Select `Signing & Capabilities`
    4. Fill out the editor.
6. Select the device to deploy to, connect it.
7. Hit the deploy button (Play arrow)
8. Enjoy

## Testing out Different Background Models
1. Add new model to the File hierarchy on the left panel. (Make sure ARrehab is a target)
2. Edit [ViewManipulation.swift](ARrehab/ARrehab/ViewManipulation.swift) line 41. Ensure that the `addBackground()` method is being called.
3. Edit [ViewController.swift](ARrehab/ARrehab/ViewController.swift) line 214. Change the `named` field to the name of the Entity you are trying to load.
3. Launch and enjoy! Large models may take a while to load.

## Branch Structure:
- content
    - content team's assets, reality composer mock ups, etc.
- avatar (Stale)
    - attempt at creating a player avatar.
- board_generation
    - Laying out the board.
- classification
    - Laying out the board automatically by classifying the ground.
- faceoff
    - Facial expression minigame

To switch to any branch: `git checkout [branch name]`

## Current Minigames:
- Laser
    - Upper body / Hand / Eye coordination. Targeting monsters with water.
- Movement
    - Physical movement. Currently asking users to squat.

# Contributing
Please see [CONTRIBUTING.md](CONTRIBUTING.md)

Please checkout the treehacks branch to see our work at TreeHacks.
`git checkout treehacks`
