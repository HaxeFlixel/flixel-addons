package flixel.addons.tile;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.addons.system.FlxAnimExt;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;

class FlxTileSpecial extends FlxBasic
{
	public static inline var ROTATE_0 = 0;
	public static inline var ROTATE_90 = 1;
	public static inline var ROTATE_270 = 2;
	
	/**
	 * The id of this tile in the tileset
	 */
	public var tileID:Int;
	
	public var flipHorizontally:Bool = false;
	public var flipVertically:Bool = false;
	
	public var rotate:Int;
	
	private var _tmp_flipH:Bool;
	private var _tmp_flipV:Bool;
	private var _tmp_rot:Int;
	
	#if flash
	private var _normalFrame:BitmapData;
	private var _flippedFrame:BitmapData;
	private var _point:Point;
	#end
	
	private var _matrix:Matrix;
	
	// Animation stuff
	private var _animation:FlxAnimExt;
	private var _currFrame:Int = 0;
	private var _lastFrame:Int = -1;
	private var _currTileId:Int;
	private var _currAnimParam:AnimParams;
	private var _frameTimer:Float = 0.0;
	
	#if flash
	private var _animRects:Array<Rectangle>;
	public var dirty:Bool = true;
	#end
	
	public function new(TilesetId:Int, FlipHorizontal:Bool, FlipVertical:Bool, Rotate:Int) 
	{
		super();
		this.tileID = TilesetId;
		this._currTileId = this.tileID;
		this.flipHorizontally = FlipHorizontal;
		this.flipVertically = FlipVertical;
		this.rotate = Rotate;
		
		#if flash
		this._normalFrame = null;
		this._flippedFrame = null;
		this._point = new Point(0, 0);
		
		_animRects = null;
		
		#end
		
		this._matrix = new Matrix();
		this._animation = null;
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		#if flash
		if (_normalFrame != null)
		{
			_normalFrame.dispose();
		}
		_normalFrame = null;
		
		if (_flippedFrame != null)
		{
			_flippedFrame.dispose();
		}
		_flippedFrame = null;
		
		_point = null;
		_animRects = null;
		#end
		
		if (_animation != null)
		{
			_animation.destroy();
		}
		_animation = null;
		_currAnimParam = null;
		_matrix = null;
	}
	
	override public function update():Void 
	{
		super.update();
		// Modified from updateAnimation() in FlxSprite
		if (_animation != null && _animation.delay > 0) 
		{
			_frameTimer += FlxG.elapsed;
			if (_frameTimer > _animation.delay) 
			{
				_lastFrame = _currFrame;
			}
			while (_frameTimer > _animation.delay) 
			{
				_frameTimer = _frameTimer - _animation.delay;
				if (_currFrame >= _animation.frames.length - 1)
				{
					_currFrame = 0;
				}
				else
				{
					_currFrame++;
				}
			}
			_currTileId = _animation.frames[_currFrame];
			if (_animation.framesData != null) 
			{
				_currAnimParam = _animation.framesData[_currFrame];
			}
		}
	}
	
	public inline function isSpecial():Bool 
	{
		return (isFlipped() || hasAnimation());
	}
	
	public inline function isFlipped():Bool 
	{
		return ((flipHorizontally || flipVertically) || rotate != ROTATE_0);
	}
	
	public inline function hasAnimation():Bool 
	{
		return (_animation != null);
	}
	
	#if flash
	public function getBitmapData(width:Int, height:Int, rect:Rectangle, bitmap:BitmapData):BitmapData 
	{
		if (_normalFrame == null)
		{
			_normalFrame = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
		}
		
		var generateFlipped:Bool = (_flippedFrame == null);
		if (generateFlipped)
		{
			_flippedFrame = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
		}

		if (generateFlipped || (hasAnimation() && _currFrame != _lastFrame)) 
		{
			_normalFrame.fillRect(_normalFrame.rect, FlxColor.TRANSPARENT);
			_flippedFrame.fillRect(_flippedFrame.rect, FlxColor.TRANSPARENT);
			
			if (_animRects != null && _animRects[_currFrame] != null) 
			{
				rect = _animRects[_currFrame];
			}
			
			_normalFrame.copyPixels(bitmap, rect, _point, null, null, true);
			_flippedFrame.draw(_normalFrame, getMatrix(width, height));
			//_lastFrame = _currFrame;
			dirty = true;
		} 
		else 
		{
			dirty = false;
		}
	
		return _flippedFrame;
	}
	
	public function getBitmapDataRect():Rectangle 
	{
		if (_flippedFrame == null) 
		{
			throw "There is no flipped frame D: D: D:!!!";
		}
		else 
		{
			return _flippedFrame.rect;
		}
	}
	
	/**
	 * Set the animation rectangles for flash
	 * @param	rects	An array with rectangles
	 */
	public function setAnimationRects(rects:Array<Rectangle>):Void 
	{
		this._animRects = rects;
	}
	#end
	
	/**
	 * Add an animation to this special tile
	 * @param	tiles		An array with the tilesetID of each frame
	 * @param	frameRate	The speed of the animation in frames per second (Default: 30)
	 */
	public function addAnimation(tiles:Array<Int>, frameRate:Float = 30, ?framesData:Array<AnimParams>):Void 
	{
		_animation = new FlxAnimExt("tileAnim", tiles, frameRate, true, framesData);
	}
	
	/**
	 * Returns the current tileID of this tile in the tileset
	 * @return The current tileID
	 */
	public function getCurrentTileId():Int 
	{
		return _currTileId;
	}
	
	/**
	 * Get the animation tiles id if any
	 * @return	An array of ids or null
	 */
	public function getAnimationTilesId():Array<Int> 
	{
		if (_animation != null) 
		{
			return _animation.frames;
		}
		
		return null;
	}
	
	/**
	 * Calculates and return the matrix
	 * @param	width	the tile width
	 * @param	height	the tile height
	 * @return	The matrix calculated
	 */
	public function getMatrix(width:Int, height:Int):Matrix 
	{
		_tmp_flipH = flipHorizontally;
		_tmp_flipV = flipVertically;
		_tmp_rot = rotate;
		
		if (_currAnimParam != null) {
			_tmp_flipH = _currAnimParam.flipHorizontal;
			_tmp_flipV = _currAnimParam.flipVertical;
			_tmp_rot = _currAnimParam.rotate;
		}
		
		_matrix.identity();
		if (_tmp_flipH) 
		{
			_matrix.scale( -1, 1);
			_matrix.translate(width, 0);
		}
		if (_tmp_flipV) 
		{
			_matrix.scale(1, -1);
			_matrix.translate(0, height);
		}
		
		if (_tmp_rot != FlxTileSpecial.ROTATE_0) 
		{
			switch(_tmp_rot) 
			{
				case FlxTileSpecial.ROTATE_90:
					_matrix.rotate(90 * FlxAngle.TO_RAD);
					_matrix.translate(width, 0);

				case FlxTileSpecial.ROTATE_270:
					_matrix.rotate(270 * FlxAngle.TO_RAD);
					_matrix.translate(0, height);
			}
		}
		
		return _matrix;
	}
}


typedef AnimParams = 
{
	var flipHorizontal:Bool;
	var flipVertical:Bool;
	var rotate:Int;
}