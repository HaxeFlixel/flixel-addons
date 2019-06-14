package flixel.addons.tile;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.animation.FlxAnimation;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxMatrix;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

class FlxTileSpecial extends FlxBasic
{
	public static inline var ROTATE_0 = 0;
	public static inline var ROTATE_90 = 1;
	public static inline var ROTATE_270 = 2;

	public var flipX:Bool = false;
	public var flipY:Bool = false;

	public var rotate:Int;

	public var frames(default, set):FlxFramesCollection;

	public var currTileId(default, set):Int = 0;
	public var currFrame(default, null):FlxFrame;

	var _tmp_flipH:Bool;
	var _tmp_flipV:Bool;
	var _tmp_rot:Int;

	var _matrix:FlxMatrix;

	// Animation stuff
	public var animation:FlxTileAnimation;

	var _currIndex:Int = 0;
	var _lastIndex:Int = -1;
	var _currAnimParam:AnimParams;
	var _frameTimer:Float = 0.0;

	public var dirty:Bool = true;

	public function new(TilesetId:Int, FlipX:Bool, FlipY:Bool, Rotate:Int)
	{
		super();

		currTileId = TilesetId;
		flipX = FlipX;
		flipY = FlipY;
		rotate = Rotate;

		_matrix = new FlxMatrix();
	}

	override public function destroy():Void
	{
		super.destroy();

		animation = FlxDestroyUtil.destroy(animation);
		_currAnimParam = null;
		_matrix = null;

		currFrame = null;
		frames = null;
	}

	// TODO: unify animation code with FlxAnimation...
	// TODO: try to move animation update code to FlxTileAnimation class
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (FlxG.renderBlit)
		{
			dirty = false;
		}
		// Modified from updateAnimation() in FlxSprite
		if (animation != null && animation.delay > 0)
		{
			_frameTimer += elapsed;
			if (_frameTimer > animation.delay)
			{
				_lastIndex = _currIndex;
			}
			while (_frameTimer > animation.delay)
			{
				_frameTimer = _frameTimer - animation.delay;
				if (_currIndex >= animation.frames.length - 1)
				{
					_currIndex = 0;
				}
				else
				{
					_currIndex++;
				}
			}
			currTileId = animation.frames[_currIndex];
			if (animation.framesData != null)
			{
				_currAnimParam = animation.framesData[_currIndex];
			}

			if (FlxG.renderBlit)
			{
				dirty = !(_currIndex == _lastIndex);
			}
		}
	}

	public inline function isSpecial():Bool
	{
		return isFlipped() || hasAnimation();
	}

	public inline function isFlipped():Bool
	{
		return (flipX || flipY) || rotate != ROTATE_0;
	}

	public inline function hasAnimation():Bool
	{
		return animation != null;
	}

	public function paint(bmd:BitmapData, at:Point):Void
	{
		if (!FlxG.renderBlit)
			return;

		_tmp_flipH = flipX;
		_tmp_flipV = flipY;
		_tmp_rot = rotate;

		if (_currAnimParam != null)
		{
			_tmp_flipH = _currAnimParam.flipX;
			_tmp_flipV = _currAnimParam.flipY;
			_tmp_rot = _currAnimParam.rotate;
		}

		var rotation:FlxFrameAngle = FlxFrameAngle.ANGLE_0;
		if (_tmp_rot == FlxTileSpecial.ROTATE_90)
		{
			rotation = FlxFrameAngle.ANGLE_90;
		}
		else if (_tmp_rot == FlxTileSpecial.ROTATE_270)
		{
			rotation = FlxFrameAngle.ANGLE_270;
		}

		currFrame.paintRotatedAndFlipped(bmd, at, rotation, _tmp_flipH, _tmp_flipV, true);
	}

	/**
	 * Add an animation to this special tile
	 * @param	tiles		An array with the tilesetID of each frame
	 * @param	frameRate	The speed of the animation in frames per second (Default: 30)
	 */
	public function addAnimation(tiles:Array<Int>, frameRate:Float = 30, ?framesData:Array<AnimParams>):Void
	{
		animation = new FlxTileAnimation("tileAnim", tiles, frameRate, true, framesData);
	}

	/**
	 * Creates tile animation and copies data from specified sprite animation (name, frame ids, framerate and looping);
	 * @param	anim	Animation to copy data from
	 */
	public function fromSpriteAnimation(anim:FlxAnimation):Void
	{
		animation = new FlxTileAnimation(anim.name, Reflect.field(anim, "_frames"), anim.frameRate, anim.looped);
	}

	/**
	 * Calculates and return the matrix
	 * @param	width	the tile width
	 * @param	height	the tile height
	 * @return	The matrix calculated
	 */
	public function getMatrix():FlxMatrix
	{
		_tmp_flipH = flipX;
		_tmp_flipV = flipY;
		_tmp_rot = rotate;

		if (_currAnimParam != null)
		{
			_tmp_flipH = _currAnimParam.flipX;
			_tmp_flipV = _currAnimParam.flipY;
			_tmp_rot = _currAnimParam.rotate;
		}

		var rotation:FlxFrameAngle = FlxFrameAngle.ANGLE_0;
		if (_tmp_rot == FlxTileSpecial.ROTATE_90)
		{
			rotation = FlxFrameAngle.ANGLE_90;
		}
		else if (_tmp_rot == FlxTileSpecial.ROTATE_270)
		{
			rotation = FlxFrameAngle.ANGLE_270;
		}

		currFrame.prepareMatrix(_matrix, rotation, _tmp_flipH, _tmp_flipV);

		return _matrix;
	}

	function set_frames(value:FlxFramesCollection):FlxFramesCollection
	{
		frames = value;

		if (value != null)
		{
			currFrame = frames.frames[currTileId];
		}

		return frames;
	}

	function set_currTileId(value:Int):Int
	{
		if (frames != null)
		{
			currFrame = frames.frames[value];
		}

		return currTileId = value;
	}
}

typedef AnimParams =
{
	var flipX:Bool;
	var flipY:Bool;
	var rotate:Int;
}
