package flixel.addons.display;

import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxBitmapDataUtil;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;

/**
 * Creating animated and rotated sprite from an un-rotated animated image.
 *
 * @version 1.0 - November 8th 2011
 * @link http://www.gameonaut.com
 * @author Simon Etienne Rozner / Gameonaut.com, ported to Haxe by Sam Batista
 * @author Slightly updated by Beeblerox.
 */
class FlxSpriteAniRot extends FlxSprite
{
	var framesCache:Array<FlxFramesCollection>;
	var rotations:Float = 0;
	var angleIndex:Int = -1;

	/**
	 * Constructor, which creates array of prerotated spritesheets for each frame in provided AnimatedGraphic.
	 *
	 * @param	AnimatedGraphic		The image you want to rotate and stamp.
	 * @param	Rotations			The number of rotation frames the final sprite should have.  For small sprites this can be quite a large number (360 even) without any problems.
	 * @param	AutoBuffer			Whether to automatically increase the image size to accomodate rotated corners.  Default is false.  Will create frames that are 150% larger on each axis than the original frame or graphic.
	 * @param	Antialiasing		Whether to use high quality rotations when creating the graphic.  Default is false.
	 * @param	Width				The width of frame in provided spritesheet.
	 * @param	Height				The height of frame in provided spritesheet
	 * @param	X					The x component of sprite's position.
	 * @param	Y					The y component of sprite's position.
	 */
	public function new(AnimatedGraphic:FlxGraphicAsset, Rotations:Int = 16, AutoBuffer:Bool = false, Antialiasing:Bool = false, Width:Int = 0,
			Height:Int = 0, X:Float = 0, Y:Float = 0)
	{
		super(X, Y);

		// Just to get the number of frames
		loadGraphic(AnimatedGraphic, true, Width, Height);
		graphic.destroyOnNoUse = false;

		rotations = Rotations;
		framesCache = [];

		var num:Int = numFrames;
		var helperSprite:FlxSprite = new FlxSprite();
		var frameToLoad:FlxFrame = null;

		// Load the graphic, create rotations every X degrees
		for (i in 0...num)
		{
			frameToLoad = frames.frames[i];

			// Create the rotation spritesheet for that frame
			helperSprite.loadRotatedFrame(frameToLoad, Rotations, Antialiasing, AutoBuffer);
			helperSprite.graphic.destroyOnNoUse = false;
			framesCache.push(helperSprite.frames);
		}

		helperSprite.destroy();

		if (AutoBuffer)
		{
			width = frameToLoad.sourceSize.x;
			height = frameToLoad.sourceSize.y;
			frameWidth = Std.int(framesCache[0].frames[0].sourceSize.x);
			frameHeight = Std.int(framesCache[0].frames[0].sourceSize.y);
			centerOffsets();
		}

		animation.destroyAnimations();
		bakedRotationAngle = 360 / Rotations;
	}

	override public function destroy():Void
	{
		framesCache = null;
		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var oldIndex:Int = angleIndex;
		var angleHelper:Int = Math.floor(angle % 360);

		while (angleHelper < 0)
		{
			angleHelper += 360;
		}

		angleIndex = Math.floor(angleHelper / bakedRotationAngle + 0.5);
		angleIndex = Std.int(angleIndex % rotations);

		if (oldIndex != angleIndex)
		{
			dirty = true;
		}
	}

	override function calcFrame(RunOnCpp:Bool = false):Void
	{
		if (bakedRotationAngle != 0)
		{
			var idx:Int = (animation.frameIndex < 0) ? 0 : animation.frameIndex;
			frame = framesCache[idx].frames[angleIndex];
		}

		if (FlxG.renderTile)
		{
			if (!RunOnCpp)
			{
				return;
			}
		}

		super.calcFrame();
	}
}
