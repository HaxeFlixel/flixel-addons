v1.0.2
------------------------------
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

v1.0.1
------------------------------
* FlxWeapon: Now works with different bullet classes (that extend FlxBullet)
* FlxBitmapFont.setFontGraphics() is now public
* FlxSpriteAniRot: Fix for non-flash targets
* api.FlxGameJolt added
* TiledLayer: Bugfix for "End of file error"
* text.FlxTypeText added
* FlxNapeState: ShapeDebug works correctly with FlxCamera again, is now also drawn below the flixel debugger, added a button to toggle nape debugging to the debugger
* ui.FlxClickArea added

v1.0.0
------------------------------
* Initial haxelib release
