# The Dragon Game

A Technical Summary of current development stage of the Dragon Game.

Updated 11/17/2020

## Overview

This sample app demonstrates a simple AR experience for iOS 12 devices. Before exploring the code, try building and running the app to familiarize yourself with the user experience it demonstrates:

1. Run the app. You will be asked to name a new world on the first launch. After that, you will be asked to select a world to load (or create new) on each launch.

2. Enter Decoration Mode with the "Decor Mode" button. You can look around and tap to place a virtual 3D object on real-world surfaces. You can place as many objects as you wish. Press the button in the lower right corner to select a different virtual object.

3. Press the Save Experience button to save the decorations to the current world. The changes will permanently become a part of the world and will appear each time you load this world.

4. Press the Discard Decor button to remove all unsaved objects. This is a particularly important feature because we do not yet allow users to reposition their objects.

5. Try to create a few different worlds, save different layouts and see them reloaded.


Follow the steps below to see how this app uses the [`ARWorldMap`][0] class to save and restore ARKit's spatial mapping state.

[0]:https://developer.apple.com/documentation/arkit/arworldmap
[1]:https://developer.apple.com/documentation/multipeerconnectivity

&nbsp;

## Getting Started

Requires Xcode 10.0, iOS 12.0 and an iOS device with A9 or later processor.

&nbsp;

## Run the AR Session and Place AR Content in Decoration Mode

This app extends the basic workflow for building an ARKit app. (For details, see [Building Your First AR Experience][10].) It defines an [`ARWorldTrackingConfiguration`][11] with plane detection enabled, then runs that configuration in the [`ARSession`][12] attached to the [`ARSCNView`][13] that displays the AR experience.

When [`UITapGestureRecognizer`][14] detects a tap on the screen, the [`handleSceneTap`](x-source-tag://PlaceObject) method uses ARKit hit-testing to find a 3D point on a real-world surface, then places an [`ARAnchor`][15] marking that position. When ARKit calls the delegate method [`renderer(_:didAdd:for:)`][16], the app loads a 3D model for [`ARSCNView`][13] to display at the anchor's position.

[10]:https://developer.apple.com/documentation/arkit/world_tracking/tracking_and_visualizing_planes
[11]:https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration
[12]:https://developer.apple.com/documentation/arkit/arsession
[13]:https://developer.apple.com/documentation/arkit/arscnview
[14]:https://developer.apple.com/documentation/uikit/uitapgesturerecognizer
[15]:https://developer.apple.com/documentation/arkit/aranchor
[16]:https://developer.apple.com/documentation/arkit/arscnviewdelegate/2865794-renderer

&nbsp;

## Capture and Save the AR World Map

An [`ARWorldMap`][0] object contains a snapshot of all the spatial mapping information that ARKit uses to locate the user's device in real-world space. To save a map that can reliably be used for restoring your AR session later, you'll first need to find a good time to capture the map. 

ARKit provides a [`worldMappingStatus`][30] value that indicates whether it's currently a good time to capture a world map (or if it's better to wait until ARKit has mapped more of the local environment). This app uses that value to provide visual feedback and choose when to make the Save Experience button available:

When the user taps the Save Experience button, the app calls [`getCurrentWorldMap`][31] to capture the map from the running ARSession, then serializes it to a [`Data`][32] object with [`NSKeyedArchiver`][33] and writes it to local storage:

To help a user resume the AR experience from this map later, the app also captures a snapshot of the camera view with the example [`SnapshotAnchor`](x-source-tag://SnapshotAnchor) class and stores it in the world map.

[30]:https://developer.apple.com/documentation/arkit/arframe/2990930-worldmappingstatus
[31]:https://developer.apple.com/documentation/arkit/arsession/2968206-getcurrentworldmap
[32]:https://developer.apple.com/documentation/foundation/data
[33]:https://developer.apple.com/documentation/foundation/nskeyedarchiver

&nbsp;

## Load and Relocalize to a Saved Map

When the app launches, it checks local storage for a world map file it may have saved in an earlier session.

If that file exists and can be deserialized as an [`ARWorldMap`][0] object, the app makes its Load Experience button available. When you tap the button, the app tells ARKit to attempt resuming the session captured in that world map, by creating and running an [`ARWorldTrackingConfiguration`][11] using that map as the [`initialWorldMap`][42].

ARKit then attempts to *relocalize* to the new world map—that is, to reconcile the received spatial-mapping information with what it senses of the local environment. This process is more likely to succeed if the user moves to areas of the local environment that they visited during the previous session. To help the user successfully resume the saved experience, this app uses the example [`SnapshotAnchor`](x-source-tag://SnapshotAnchor) class to save a camera image in the world map, then displays that image while ARKit is relocalizing.

[42]:https://developer.apple.com/documentation/arkit/arworldtrackingconfiguration/2968180-initialworldmap

&nbsp;

## Restore AR Content After Relocalization 

Saving a world map also archives all anchors currently associated with the AR session. After you successfully run a session from a saved world map, the session contains all anchors previously saved in the map. You can use saved anchors to restore virtual content from a previous session.

In this app, after relocalizing to a previously saved world map, the virtual object placed in the previous session automatically appears at its saved position. The same [`ARSCNView`][13] delegate method [`renderer(_:didAdd:for:)`][16] fires both when you directly add an anchor to the session and when the session restores anchors from a world map. 

This app uses the [`ARAnchor`][15] [`name`][50] property to distinguish between the types of objects to be loaded. In the [`renderer(_:didAdd:for:)`] method, we then extract this information from the anchor name and load the appropriate virtual object node to be placed at the anchor.

&nbsp;

## The Virtual Object

The app currently can only place SCN objects. A bit additional work is needed to place virtual objects of other types (such as usdz)
