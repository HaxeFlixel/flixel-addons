3.3.0 (December 10, 2024)
------------------------------
#### New Features:
- `FlxRadialGauge`: Refactor `FlxPieDial` add replacement ([444](https://github.com/HaxeFlixel/flixel-addons/pull/444))
  - `FlxRadialWipeShader`: Shader that masks sprite radially, can be applied to of any static sprite (doesn't work with animations, yet, but neither did FlxPieDial). Shaders only work on non-Flash targets
  - `FlxRadialGauge`: Same as `FlxPieDial` but uses less memory, shows more percentages, and performs better
  - `FlxPieDialUtils`: Moved all logic from `FlxPieDial` to a shared util

#### Changes and improvements:
- Compatibility with Flixel 5.9.0 ([431](https://github.com/HaxeFlixel/flixel-addons/pull/431))([432](https://github.com/HaxeFlixel/flixel-addons/pull/432))([433](https://github.com/HaxeFlixel/flixel-addons/pull/433))([436](https://github.com/HaxeFlixel/flixel-addons/pull/436))([437](https://github.com/HaxeFlixel/flixel-addons/pull/437))([440](https://github.com/HaxeFlixel/flixel-addons/pull/440))([441](https://github.com/HaxeFlixel/flixel-addons/pull/441))
  - Deprecated `FlxRayCastTilemap`
  - Minor upkeep for `FlxTilemapExt`, `FlxOgmo3Loader`, `FlxOgmo3Loader`, `FlxWeapon`, `FlxNapeTilemap`, `FlxTrail`, `FlxExtendedMouseSprite`, `FlxSlider`, `FlxTransitionSprite`
- `FlxTiledSprite`: Honor `clipRect` ([435](https://github.com/HaxeFlixel/flixel-addons/pull/435))
- `FlxRuntimeShader`: Refactor and improve readibility ([442](https://github.com/HaxeFlixel/flixel-addons/pull/442))
- Assets: Ran oxipng on all images ([445](https://github.com/HaxeFlixel/flixel-addons/pull/445))
- `FlxTrail`: Organize logic into various methods to allow overriding particular behavior ([447](https://github.com/HaxeFlixel/flixel-addons/pull/447))
- `TiledObject`: Add `POINT` type ([448](https://github.com/HaxeFlixel/flixel-addons/pull/448))
- `TiledLayer`: Add `parallaxX` and `parallaxY` ([449](https://github.com/HaxeFlixel/flixel-addons/pull/449))
- Remove all implicit `Int` casts from/to `FlxDirectionFlags` ([451](https://github.com/HaxeFlixel/flixel-addons/pull/451))

#### Bugfixes:
- `FlxTypeText`: Honors `prefix` on `reset` calls ([395](https://github.com/HaxeFlixel/flixel-addons/pull/395))

3.2.3 (May 15, 2024)
------------------------------

#### Changes and improvements:
- `FlxClickArea`: Compatibility with Flixel 5.7.0 ([425](https://github.com/HaxeFlixel/flixel-addons/pull/425))

#### Bugfixes:
- `FlxBackdrop`: fix matrix leaks ([426](https://github.com/HaxeFlixel/flixel-addons/pull/426))
- `FlxRuntimeShader`: Fix errors with flixel-docs CI ([429](https://github.com/HaxeFlixel/flixel-addons/pull/429))

3.2.2 (March 10, 2024)
------------------------------
#### Dependencies:
- Minimum versions allowed:
	- Flixel: 5.3.0
	- OpenFl: 9.2.2
	- Lime: 8.0.2
	- Haxe: 4.2.5

#### Changes and improvements:
- `FlxFSM`: Fix `FlxPool` deprecation warnings from Flixel 5.4.0 ([#409](https://github.com/HaxeFlixel/flixel-addons/pull/409))
- `TransitionData`: add `cameraMode` field to help ensure the transition shows on top ([#410](https://github.com/HaxeFlixel/flixel-addons/pull/410))
- `FlxRuntimeShader`: Throw incompatibility error on nme or flash ([#414](https://github.com/HaxeFlixel/flixel-addons/pull/414))
- `FlxNestedSprite`: Prevent drawing default png ([#412](https://github.com/HaxeFlixel/flixel-addons/pull/412))

#### Bugfixes:
- `TransitionFade`: Fix bug with persistent images ([#415](https://github.com/HaxeFlixel/flixel-addons/pull/415))

3.2.1 (September 26, 2023)
------------------------------
#### Changes and improvements:
- `FlxMouseSpring`: Now works with `FlxSprite` rather than just `FlxExtendedSprite` ([#405](https://github.com/HaxeFlixel/flixel-addons/pull/405))
- `FlxExtendedSprite`: Deprecated for `FlxExtendedMouseSprite`, no longer uses `FlxMouseControl` ([#405](https://github.com/HaxeFlixel/flixel-addons/pull/405))

#### Bugfixes:
- `FlxBackdrop`: Change spacing constructor args to floats ([#408](https://github.com/HaxeFlixel/flixel-addons/pull/408))

3.2.0 (August 15, 2023)
------------------------------
#### New Features:
- `FlxRuntimeShader`: Generate shaders from glsl provided at runtime ([#399](https://github.com/HaxeFlixel/flixel-addons/pull/399))

#### Changes and improvements:
- `FlxSkewedSprite`: Allow shaders ([#390](https://github.com/HaxeFlixel/flixel-addons/pull/390))
- `FlxBackdrop`: Use pooled `FlxPoint` for `spacing` ([#394](https://github.com/HaxeFlixel/flixel-addons/pull/394))
- `FlxMouseControl`: Deprecated, use [FlxMouseEvent](https://haxeflixel.com/demos/FlxMouseEvent/) instead
- `FlxTransitionSprite`: Fix transition sprite graphics on html5 ([#396](https://github.com/HaxeFlixel/flixel-addons/pull/396))
	- Compress and include asset paths for transition images:
		- "flixel/images/transitions/circle.png"
		- "flixel/images/transitions/square.png"
		- "flixel/images/transitions/diamond.png"
		- "flixel/images/transitions/diagonal_gradient.png"
	- Fix graphic classes
		- `GraphicTransTileCircle`
		- `GraphicTransTileSquare`
		- `GraphicTransTileDiamond`
		- `GraphicDiagonalGradient`
	- prevent double update on transitions
	- optimize wipe transitions, especially diagonal wipe
 - Replace `flash` imports with `openfl` equivalents, where possible ([#400](https://github.com/HaxeFlixel/flixel-addons/pull/400))
 - `FlxFSMTransitionTable`: Add `removeNow` arg to `remove` and `replace` ([#401](https://github.com/HaxeFlixel/flixel-addons/pull/401))

3.1.1 (May 19, 2023)
------------------------------
#### Changes and improvements:
- Fix `@:enum` deprecation warnings in haxe 4.3.1

3.1.0 (April 25, 2023)
------------------------------
#### Dependencies:
- Dropped support for haxe 4.0 and 4.1, use 4.2.5 or higher
- Flixel 5.3.0 compatibility, flixel-addons 3.1.0 will not work with flixel 5.2 or lower.

#### Changes and improvements:
- `FlxTilemapExt`: Implement scaling ([#384](https://github.com/HaxeFlixel/flixel-addons/pull/384))
- Improve docs ([#376](https://github.com/HaxeFlixel/flixel-addons/pull/376))
- `FlxTransitionableState`: Use `startOutro` instead of `switchTo` ([#382](https://github.com/HaxeFlixel/flixel-addons/pull/382))

3.0.2 (January 18, 2023)
------------------------------
* Fix haxelib caching issue from reuploading 3.0.1

3.0.1 (January 18, 2023)
------------------------------
* Compatibility with flixel 5.2.0 (fix deprecation warnings in FlxTilemapExt)

3.0.0 (November 19, 2022)
------------------------------
* `FlxBackdrop` - Completely overhauled to work with animation, scale, angle, camera zoom nd shaders ([#373](https://github.com/HaxeFlixel/flixel-addons/pull/373))

2.12.0 (November 19, 2022)
------------------------------
* Compatibility with flixel 5.0.0-alpha
* A lot of fixes for `FlxGameJolt.hx` (#367)

2.11.0 (September 12, 2021)
------------------------------
* Compatibility with flixel 4.10.0

2.10.0 (April 11, 2021)
------------------------------
* `FlxOgmo3Loader`: added `loadTilemapExt()` (#349)
* `TiledTileLayer`: fixed `tile` array not being generated with `encoding = 'csv'` (#347)
* `TransitionFade`: fixed `region` support (#348)

2.9.0 (July 2, 2020)
------------------------------
* `FlxOgmoLoader`: added an optional `tilemap` parameter to `loadTilemap()`
* `FlxOgmo3Loader`: added an optional `tilemap` parameter to `loadTilemap()` (#341)
* `FlxTilemapExt`: added `setDownwardsGlue()` (#339)
* Added `flixel.addons.display.FlxShaderMaskCamera` (#342)
* Fixed `Std.is()` deprecation warnings with Haxe 4.2

2.8.0 (February 8, 2020)
------------------------------
* `FlxSliceSprite`:
	* added `sourceRect` and `fillCenter` (#334)
	* redid the implementation to make it work on older machines and in Safari (#335)
* Added `flixel.addons.editors.ogmo.FlxOgmo3Loader` (#337)
* `flixel.addons.editors.tiled`: added support for grouped layers (#332)

2.7.5 (April 3, 2019)
------------------------------
* `TiledMap`: fixed a crash on HashLink

2.7.4 (April 2, 2019)
------------------------------
* `FlxKongregate`: fixed compatibility with OpenFL 8.9.0

2.7.3 (February 8, 2019)
------------------------------
* `FlxSpine`: fixed compatibility with Haxe 4.0.0-rc.1

2.7.2 (February 4, 2019)
------------------------------
* Compatibility with flixel 4.6.0 and Haxe 4.0.0-rc.1
* `flixel.addons.editors.tiled`:
	* `TiledTileSet`: fixed `numRows` and `numCols` being flipped (#326)
	* added support for Tiled Collision Editor (#327)
	* `TiledImageLayer`: improved documentation (#329)

2.7.1 (November 10, 2018)
------------------------------
* `FlxSimplex`: improved `simplexTiles()` by basing it on 4D noise generation (#324)
* `TiledPropertySet`: fixed compilation with Haxe 4 preview 5

2.7.0 (July 5, 2018)
------------------------------
* `FlxSliceSprite`: added `scale` support (#318)
* `TiledTileSet`: added tile `type` and `probability` attributes (#320)
* `FlxMouseControl`: fixed down not being distinguishable from drag (#307)
* Added `flixel.addons.util.FlxSimplex` (#280)
* `FlxTypeText`: fixed `applyMarkup` (#305)
* `TiledMap`: guess `rootPath` based on the data asset path (#315)

2.6.0 (May 4, 2018)
------------------------------
* Compatibility with flixel 4.4.0
* `FlxShapeCircle`: fixed some rounding issues (#304)
* `FlxExtendedSprite`: fixed click callbacks not working without drag (#308)
* `flixel.addons.editors.tiled`:
	* fixed loading of external tile sets (#312)
	* improved error messages for invalid paths (#312)
	* fixed compatibility with Haxe 4
* `FlxSlider`: fixed bounds not being updated after position changes (#306)

2.5.0 (July 22, 2017)
------------------------------
* Compatibility with flixel 4.3.0

2.4.1 (May 17, 2017)
------------------------------
* `FlxTypeText`: fixed a crash caused by `sounds` being `null`

2.4.0 (May 13, 2017)
------------------------------
* `FlxWeapon`: added `angleOffset` to `FlxWeaponFireFrom.PARENT` (#292)
* `FlxTypeText`:
	* changed `start()` and `erase()` to always set the callbacks (#293)
	* stop sounds when typing is complete (#295)
	* added `finishSounds` (#296)
* `TiledTileLayer`: removed an unnecessary warning on HTML5 (3c79b46)

2.3.0 (February 10, 2017)
------------------------------
* `FlxBackdrop`: fixed `color` not working with tilesheet rendering (#277) 
* `FlxWeapon`: fixed `FIRE_FROM_PARENT_FACING` angles (#259)
* `FlxSliceSprite`:
	* added setters for `alpha` and `color` (#276)
	* fixed a rendering issue on Flash (#275)
* `flixel.addons.editors.spine`: support for spinehaxe version 3.5.0 (#281)
* `TiledObject`: fixed `gid` handling of flipped objects (#287)

2.2.0 (October 11, 2016)
------------------------------
* Compatibility with flixel 4.2.0
* `FlxWeaponFireFrom`: added a `useParentAngle` argument to `PARENT` (#261)
* `FlxPexParser`:
	* added a `scale` argument to `new()` (#263)
	* added support for blend modes (#270)
* `FlxSpine`: fixed an issue with texture loading and state switches (#265)
* `FlxTypeText`: added support for adding / removing more than one char per frame (#267)
* `flixel.addons.editors.tiled`: added support for animated tiles (#268)
* `FlxFSM`: fixed a runtime error on HTML5 (#271)
* `FlxSliceSprite`: fixed incorrect vertex positions on the bottom part (#272)
* `FlxNapeSpace`: fixed `drawDebug` positioning with scaling (00b2b37)

2.1.0 (July 10, 2016)
------------------------------
* Compatibility with flixel 4.1.0
* `FlxTrailEffect`: added `clear()` (#229) 
* `FlxOutlineEffect`: added `mode` / `FlxOutlineMode` and `quality` (#230)
* `FlxWaveEffect`: added `interlaceOffset` (#232) 
* `FlxNapeTilemap`: added a null check to `placeCustomPolygon()` (#235)
* `FlxEffectSprite`: added `updateTargetAnimation` (#236) 
* `FlxControlHandler`: added `invertX` and `invertY` (#239) 
* `FlxBackdrop`:
	* added support for `alpha` (#244)
	* added support for `offset`
* `TiledMap`:
	* added a `rootPath` argument to `new()` (#245)
	* renamed `FlxTiledAsset` to `FlxTiledMapAsset` (#245)
* `TiledTileLayer`:
	* added support for CSV encoding to `tileArray` (#245)
	* changed `new()`'s `data` argument from `Dynamic` to `FlxTiledTileAsset` (#245)
* `TiledObject`:
	* changed the default name from `"[object]"` to `""` (#247)
	* [Neko] fixed the types of `flippedHorizontally` / `flippedVertically`
* `TiledLayer`: added `offsetX` and `offsetY` (#251)
* `FlxFSM`: [Neko] fixed an invalid field access error (#257)
* Added `FlxTiledSprite`
* Added `FlxSliceSprite`

2.0.0 (February 16, 2016)
------------------------------
* Compatibility with flixel 4.0.0
* `flixel.addons.editors.tiled`:
	* `TiledLayer` and `TiledObjectGroup` have been replaced with `TiledTileLayer` and `TiledObjectLayer` with a common base class `TiledLayer`
	* `TiledMap` now stores object layers and tile layers in a single array, `layers`, to maintain the order of object and tile layers
	* `TileTileLayer`: added `encoding`
	* `TiledTileSet`: added `"id"` to `tileProps`
	* added `TiledImageLayer`
	* added `TiledImageTile` and `TiledTileSet#tileImagesSources`
* `FlxTileSpecial`:
	* fixed bugs related to rotation happening after flipping
	* `flipHorizontal` -> `flipX`
	* `flipVertical` -> `flipY`
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
	* replaced `sound` by a `sounds` array, from which one is randomly picked
	* fixed jumping between lines during typing
	* added `useDefaultSound` which is `false` by default
* added `flixel.addons.editors.pex.FlxPexParser`
* added `flixel.addons.transition`
* added `flixel.addons.util.FlxScene`
* `flixel.addons.nape`:
	* refactored `FlxNapeState` into a plugin called `FlxNapeSpace`, making it possible to use nape with other `FlxState` child classes like `FlxUIState`
	* `FlxNapeSpace`: added `napePhysicsEnabled`
	* `FlxNapeSpace`: made `shapeDebug` public
	* `FlxNapeSprite`: `setPosition()` is now overridden and sets `body.position`
	* `FlxNapeSprite#new()`: the `EnablePhysics` argument is now no longer ignored if `CreateRectangularBody` is `false`
* `flixel.addons.plugin.taskManager`: 
	* `AntTaskManager` -> `FlxTaskManager`
	* `AntTask` -> `FlxTask`
* `FlxBackdrop`: added support for  `scale`, `loadGraphic()` and `loadFrame()`
* `flixel.addons.editors.spine`:
	* now uses [spinehaxe](https://github.com/bendmorris/spinehaxe) instead of [spinehx](https://github.com/nitrobin/spinehx)
	* `FlxSpine#readSkeletonData()` now allows for different atlas and animation file names
* `FlxOgmoLoader`:
	* added `getProperty()`
	* the constructor no longer sets the camera bounds
* `FlxScreenGrab`:
	* fixed `defineHotkeys()` arguments overriding those in `grab()`
	* now uses linc_dialogs instead of systools on native targets
* `FlxTilemapExt`:
	* added support for slopes with 22.5 and 67.5 degrees
	* added `setGentle()` and `setSteep()`
	* removed `setClouds()`
* `FlxExtendedSprite`: `mouseStartDragCallback` and `mouseStopDragCallback` now work 
* added `flixel.addons.display.FlxPieDial`
* `FlxGridOverlay`: removed the non-functional `AddLegend` arguments
* `FlxZoomCamera`: made `zoomSpeed` and `zoomMargin` public
* added `flixel.addons.text.FlxTextField` (moved from core Flixel)
* added `flixel.addons.effects.chainable`:
	* `IFlxEffect`
	* `FlxEffectSprite`
	* `FlxGlitchEffect` (replaces `FlxGlitchSprite`)
	* `FlxWaveEffect` (replaces `FlxWaveSprite`)
	* `FlxRainbowEffect`
	* `FlxOutlineEffect`
	* `FlxTrailEffect`
	* `FlxShakeEffect`
* added `flixel.addons.effects.FlxClothSprite`

1.1.1 (December 15, 2015)
------------------------------
* Fix compilation with OpenFL 3.5 / Lime 2.8

1.1.0 (April 24, 2014)
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

1.0.3 (February 21, 2014)
------------------------------
* Compatibility with flixel 3.2.0
* FlxOgmoLoader: add loadRectangles()
* FlxNapeSprite: fix crash without a body
* FlxNestedSprite: compatibility with facing

1.0.2 (February 6, 2014)
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

1.0.1 (December 28, 2013)
------------------------------
* FlxWeapon: Now works with different bullet classes (that extend FlxBullet)
* FlxBitmapFont.setFontGraphics() is now public
* FlxSpriteAniRot: Fix for non-flash targets
* api.FlxGameJolt added
* TiledLayer: Bugfix for "End of file error"
* text.FlxTypeText added
* FlxNapeState: ShapeDebug works correctly with FlxCamera again, is now also drawn below the flixel debugger, added a button to toggle nape debugging to the debugger
* ui.FlxClickArea added

1.0.0 (November 2, 2013)
------------------------------
* Initial haxelib release
