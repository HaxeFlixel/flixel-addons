package flixel.addons.tile;

import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAnim;
import flixel.util.FlxAngle;
import flixel.util.FlxColor;

class FlxTileSpecial extends FlxBasic
{
	public static var ROTATE_0 = 0;
	public static var ROTATE_90 = 1;
	public static var ROTATE_270 = 2;
	
	/**
	 * The id of this tile in the tileset
	 */
	public var tileID:Int;
	
	public var flipHorizontally:Bool = false;
	public var flipVertically:Bool = false;
	
	public var rotate:Int;
	
	#if flash
	private var _normalFrame:BitmapData;
	private var _flippedFrame:BitmapData;
	private var _point:Point;
	#end
	
	private var _matrix:Matrix;
	
	// Animation stuff
	private var _animation:FlxAnim;
	private var _currFrame:Int = 0;
	private var _currTileId:Int;
	private var _frameTimer:Float = 0.0;
	
	public function new(tilesetID:Int, FlipHorizontal:Bool, FlipVertical:Bool, Rotate:Int) 
	{
		super();
		this.tileID = tilesetID;
		this._currTileId = this.tileID;
		this.flipHorizontally = FlipHorizontal;
		this.flipVertically = FlipVertical;
		this.rotate = Rotate;
		
		#if flash
		this._normalFrame = null;
		this._flippedFrame = null;
		this._point = new Point(0, 0);
		#end
		
		this._matrix = new Matrix();
		this._animation = null;
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		
		#if flash
		_normalFrame.dispose();
		_flippedFrame.dispose();
		_normalFrame = null;
		_flippedFrame = null;
		_point = null;
		#end
		
		
		_animation.destroy();
		_animation = null;
		_matrix = null;
	}
	
	override public function update():Void 
	{
		super.update();
		// Modified from updateAnimation() in FlxSprite
		if (_animation != null && _animation.delay > 0) {
			_frameTimer += FlxG.elapsed;
			while (_frameTimer > _animation.delay) {
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
		}
	}
	
	public function isSpecial():Bool {
		return (((flipHorizontally || flipVertically) || rotate != ROTATE_0) || _animation != null);
	}
	
	#if flash
	public function getBitmapData(width:Int, height:Int, rect:Rectangle, bitmap:BitmapData):BitmapData {
		if (_flippedFrame == null) {
			_normalFrame = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
			_flippedFrame = new BitmapData(width, height, true, FlxColor.TRANSPARENT);
			
			_normalFrame.copyPixels(bitmap, rect, _point, null, null, true);
			
			
			_flippedFrame.draw(_normalFrame, getMatrix(width, height));			
		}
	
		return _flippedFrame;
	}
	
	public function getBitmapDataRect():Rectangle {
		if (_flippedFrame == null) {
			throw "The is no flipped frame D: D: D:!!!";
		} else {
			return _flippedFrame.rect;
		}
	}
	#end
	
	/**
	 * Add an animation to this special tile
	 * @param	tiles		An array with the tilesetID of each frame
	 * @param	frameRate	The speed of the animation in frames per second (Default: 30)
	 */
	public function addAnimation(tiles:Array<Int>, frameRate:Float = 30):Void {
		_animation = new FlxAnim("tileAnim", tiles, frameRate, true);
	}
	
	/**
	 * Returns the current tileID of this tile in the tileset
	 * @return The current tileID
	 */
	public function getCurrentTileId():Int {
		return _currTileId;
	}
	
	/**
	 * Calculates and return the matrix
	 * @param	width	the tile width
	 * @param	height	the tile height
	 * @return	The matrix calculated
	 */
	public function getMatrix(width:Int, height:Int):Matrix {
		_matrix.identity();
		if(flipHorizontally) {
			_matrix.scale( -1, 1);
			_matrix.translate(width, 0);
		}
		if (flipVertically) {
			_matrix.scale(1, -1);
			_matrix.translate(0, height);
		}
		
		if (rotate != FlxTileSpecial.ROTATE_0) {
			switch(rotate) {
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