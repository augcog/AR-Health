# AR for Healthcare
AR rehabilitation app designed for UCSF children's hospital. This is a research project done under the advisement of Professor Allen Yang and Kat Quigley.

A Technical Summary of current development stage of the app.

Updated 07/12/2021

## Getting Started

Requires Xcode 10.0, iOS 12.0 and an iOS device with A9 or later processor.

1. Launch Terminal (You can find this via Spotlight)
2. Clone the repository git clone https://www.github.com/augcog/AR-Health.git
3. Switch to the Daniel branch. git checkout daniel
4. From finder, launch the project (Double click AR-Health/AR-Health/AR-Health.xcodeproj). You can also launch from XCode
5. Change the signing certificate to your own Apple Developer account.
    1. In the File hierarchy on the left panel, select the blue Xcode project icon (root of the hierarchy).
    2. In the main center editor on the top left there is a drop down, select ARrehab (the icon should be an A made of brushes)
    3. Select Signing & Capabilities
    4. Fill out the editor.
6. Select the device to deploy to, connect it.
7. Hit the deploy button (Play arrow)
8. Enjoy

&nbsp;

## Instructions

1. Open the app.
2. First scan your surroundings until the onboarding UI appears at the bottom.
3. Name your world. (There may be an issue with the UI where the keyboard covers up the text field, will fix in a future update)
4. Next, you will be defining your garden boundary.
    1. First, place your phone on the ground and click "Set Garden Ground"
    2. (NOT IN CURRENT BUILD) You will see a fence post. Start walking along a path that you want to be your garden boundary.
    3. (NOT IN CURRENT BUILD) After finishing walking, click "Finish Walking" and see the boundary you created.
    4. When the full fence assembles, you will be led to a confirmation UI. Click "Yes" if you are satisfied with your garden or "No" to repeat the boundary steps again.
5. You will have the option to place some decorations.
    1. To start the decoration process, click "Add Decorations", otherwise, click "Skip"
    2. There is a button with a label for a decoration (i.e. guitar). This is the current object in queue for you to place. Click this button to use other decoration objects
    3. If you want to place that decoration, click "Add"
    4. If you are satisfied for now with the decor, click "Done"

&nbsp;

## Overview

The Aspects of the App
1. Garden Creation (in progress)
    1. When defining the garden, user should be able to walk along a path that becomes the boundary for the garden.
    2. Current build does not have the implementation yet, will be available in future update soon
2. Garden Decoration (in progress)
    1. Users should be able to place decorations by walking up to a location and adding their desired item to wherever their device is.
    2. Ability to remove decorations will be available in future update soon
3. Dragon Pet Interaction (in progress)
    1. User should be able to interact with a dragon pet inside their garden that will also interact with the user during minigames.
    2. Full implementation coming later.
4. Saving and Loading Worlds (in progress)
    1. User should be able to save a world they have created in a certain area (with their garden and decorations) and be able to load the world back again when they find themselves in the same area again.
    2. Previous codebase for doing so exists and is written using SceneKit, will work on transferring this to RealityKit in next update soon

&nbsp;
