?.?.?
------------------------------
* Compatibility with flixel 4.0.0
* `flixel.addons.editors.tiled`:
 * `TiledLayer` and `TiledObjectGroup` have been replaced with `TiledTileLayer` and `TiledObjectLayer` with a common base class `TiledLayer`
 * `TiledMap` now stores object layers and tile layers in a single array, `layers`, to maintain the order of object and tile layers
 * `TileTileLayer`: added `encoding`
* `FlxTileSpecial`:
 * fixed bugs related to rotation happening after flipping
 * `flipHorizontal` -> `flipX`
 * `flipVertical` -> `flipY`
* `flixel.addons.effects.WaveMode` -> `flixel.addons.effects.FlxWaveMode`
* `flixel.addons.effects.GlitchDirection` -> `flixel.addons.effects.FlxGlitchDirection`
* added `flixel.addons.util.FlxFSM`
* `FlxTrail`:
 * now extends `FlxSpriteGroup`
 * now supports animations
* `FlxTrailArea`: fixed the `offset` of sprites not being taken into account
* `flixel.addons.weapon`:
 * abstracted `FlxWeapon` into `FlxTypedWeapon` (`FlxWeapon` is now a `typedef` for `FlxTypedWeapon<FlxBullet>`)
 * `FlxTypedWeapon#new()` now requires a `BulletFactory` function
 * moved firing logic from `FlxBullet` to `FlxTypedWeapon`
 * removed `onFireCallback` and `onFireSound`
* `FlxTypeText`:
 * changed `Dynamic` callbacks to `Void->Void`
 * replaced `sound` by a `sounds` array, from which one is randomnly picked
 * added `useDefaultSound` which is `false` by default
* added `flixel.addons.editors.pex.FlxPexParser`
* added `flixel.addons.transition`
* added `flixel.addons.util.FlxScene`
* added `flixel.addons.effects.FlxOutline`
* added `flixel.addons.effects.FlxRainbowSprite`
* `flixel.addons.nape`:
 * refactored `FlxNapeState` into a plugin called `FlxNapeSpace`, making it possible to use nape with other `FlxState` child classes like `FlxUIState`
 * `FlxNapeSpace`: added `napePhysicsEnabled`
 * `FlxNapeSpace`: made `shapeDebug` public
 * `FlxNapeSprite`: `setPosition()` is now overriden and sets `body.position`
 * `FlxNapeSprite#new()`: the `EnablePhysics` argument is now no longer ignored if `CreateRectangularBody` is `false`
* `flixel.addons.plugin.taskManager`: 
 * `AntTaskManager` -> `FlxTaskManager`
 * `AntTask` -> `FlxTask`
* `FlxBackdrop` now supports `scale`, `loadGraphic()` and `loadFrame()`
* `flixel.addons.editors.spine`:
 * now uses [spinehaxe](https://github.com/bendmorris/spinehaxe) instead of [spinehx](https://github.com/nitrobin/spinehx)
 * `FlxSpine#readSkeletonData()` now allows for different atlas and animation file names
* `FlxOgmoLoader`: added `getProperty()`
* `FlxScreenGrab`: fixed `defineHotkeys()` arguments overriding those in `grab()`

1.1.1
------------------------------
* Fix compilation with OpenFL 3.5 / Lime 2.8

1.1.0
------------------------------
* Compatibility with flixel 3.3.0
* FlxClickArea: use Void->Void callbacks instead of Dynamic ones
* Refactored StarFieldFX into FlxStarField2D and FlxStarField3D
* FlxBullet: removed redundant xGravity, yGravity, maxVelocityX and maxVelocityY
* FlxButtonPlus:
 * Fixed initial text visibility
 * Added setters for the member sprites and texts so you can change them
 * Constructor params X and Y are now Floats
* FlxExtendedSprite: mouseStartDragCallback and mouseStopDragCallback now use MouseCallback (instead of Dynamic)
* FlxSlider: fixed uniqueness of the body sprite graphic
* FlxNestedSprite: fixed a potential issue in destroy()
* TiledObjectGroup: 
 * Removed x, y, width and height vars
 * Added map and color vars
* FlxTypeText: added skip()
* FlxNapeState: fixed issue with nape debug draw not showing on native targets
* Refactored AntTaskManager:
 * Switched to Bool->Void callbacks as opposed to Dynamic
 * Now extends FlxBasic and has to be add()ed
 * Removed pause variable
* FlxControlHandler: added compensation for diagonal movement
* Added FlxNapeTilemap
* Added FlxWaveSprite
* Added FlxGlitchSprite

1.0.3
------------------------------
* Compatibility with flixel 3.2.0
* FlxOgmoLoader: add loadRectangles()
* FlxNapeSprite: fix crash without a body
* FlxNestedSprite: compatibility with facing

1.0.2
------------------------------
* Compatibility with flixel 3.1.0
* FlxButtonPlus:
  * fixed button graphic always being white
  * use Void->Void for the callback function for consistency with the FlxTypedButton changes ([more info](https://github.com/HaxeFlixel/flixel/issues/805?source=cc))
* Moved shape classes from flixel-ui to flixel.addons.display.shapes
* Added FlxAsyncLoop
* FlxNestedSprite: 
 * fixes for update and draw calls
 * added relativeAlpha to fix the alpha calculation
* FlxSkewedSprite:
  * added SimpleGraphic param to the constructor
  * now correctly works with origin on cpp targets
  * exposed the transformation matrix via transformMatrix and matrixExposed
* Moved FlxTrail, FlxTrailArea and FlxSlider into flixel-addons

1.0.1
------------------------------
* FlxWeapon: Now works with different bullet classes (that extend FlxBullet)
* FlxBitmapFont.setFontGraphics() is now public
* FlxSpriteAniRot: Fix for non-flash targets
* api.FlxGameJolt added
* TiledLayer: Bugfix for "End of file error"
* text.FlxTypeText added
* FlxNapeState: ShapeDebug works correctly with FlxCamera again, is now also drawn below the flixel debugger, added a button to toggle nape debugging to the debugger
* ui.FlxClickArea added

1.0.0
------------------------------
* Initial haxelib release
