package flixel.addons.display;

import openfl.geom.ColorTransform;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

using flixel.util.FlxColorTransformUtil;

/**
 * Some sort of DisplayObjectContainer but very limited.
 * It can contain only other FlxNestedSprites.
 * @author Zaphod
 */
class FlxNestedSprite extends FlxSprite
{
	/**
	 * Internal variable to determine the parent of the nested sprite.
	 */
	var _parent:FlxNestedSprite;

	@:noCompletion
	@:deprecated("`relativeX` is deprecated. Use `x` instead.")
	/**
	 * X position of this sprite relative to parent, 0 by default
	 */
	public var relativeX:Float = 0;

	@:noCompletion
	@:deprecated("`relativeY` is deprecated. Use `y` instead.")
	/**
	 * Y position of this sprite relative to parent, 0 by default
	 */
	public var relativeY:Float = 0;
	
	@:noCompletion
	@:deprecated("`relativeAngle` is deprecated. Use `angle` instead.")
	/**
	 * Angle of this sprite relative to parent
	 */
	public var relativeAngle:Float = 0;
	
	@:noCompletion
	@:deprecated("`relativeAngularVelocity` is deprecated. Use `angularVelocity` instead.")
	/**
	 * Angular velocity relative to parent sprite
	 */
	public var relativeAngularVelocity:Float = 0;
	
	@:noCompletion
	@:deprecated("relativeAngularAcceleration is deprecated. Use `angularAcceleration` instead.")
	/**
	 * Angular acceleration relative to parent sprite
	 */
	public var relativeAngularAcceleration:Float = 0;
	@:noCompletion
	@:deprecated("`relativeAlpha` is deprecated. Use `alpha` instead.")
	public var relativeAlpha:Float = 1;
	
	@:noCompletion
	@:deprecated("`relativeScale` is deprecated. Use `scale` instead.")
	/**
	 * Scale of this sprite relative to parent
	 */
	public var relativeScale(default, null):FlxPoint = FlxPoint.get(1, 1);
	
	@:noCompletion
	@:deprecated("`relativeVelocity` is deprecated. Use `velocity` instead.")
	/**
	 * Velocity relative to parent sprite
	 */
	public var relativeVelocity(default, null):FlxPoint = FlxPoint.get();
	
	@:noCompletion
	@:deprecated("`relativeAcceleration` is deprecated. Use `acceleration` instead.")
	/**
	 * Acceleration relative to parent sprite
	 */
	public var relativeAcceleration(default, null):FlxPoint = FlxPoint.get();

	
	/**
	 * All FlxNestedSprites in this list.
	 */
	public var children(default, null):Array<FlxNestedSprite> = [];

	/**
	 * Amount of Graphics in this list.
	 */
	public var count(get, never):Int;
	
	/**
	 * Internal variable, a concatenation between the parent's `relativeColorTransform` and `colorTransform` 
	 */
	var relativeColorTransform:ColorTransform;

	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		children = FlxDestroyUtil.destroyArray(children);
		_parent = null;
	}

	/**
	 * Adds the FlxNestedSprite to the children list.
	 *
	 * @param	Child	The FlxNestedSprite to add.
	 * @return	The added FlxNestedSprite.
	 */
	public function add(Child:FlxNestedSprite):FlxNestedSprite
	{
		if (children.contains(Child))
			return Child;

		children.push(Child);
		Child._parent = this;

		return Child;
	}
	override function initVars()
	{
		relativeColorTransform = new ColorTransform();
		super.initVars();
	}

	/**
	 * Removes the FlxNestedSprite from the children list.
	 *
	 * @param	Child	The FlxNestedSprite to remove.
	 * @return	The removed FlxNestedSprite.
	 */
	public function remove(Child:FlxNestedSprite):FlxNestedSprite
	{
		var index:Int = children.indexOf(Child);

		if (index >= 0)
			children.splice(index, 1);
		
		Child._parent = null;

		return Child;
	}

	/**
	 * Removes the FlxNestedSprite from the position in the children list.
	 *
	 * @param	Index	Index to remove.
	 */
	public function removeAt(Index:Int = 0):FlxNestedSprite
	{
		if (children.length < Index || Index < 0)
			return null;

		return remove(children[Index]);
	}

	/**
	 * Removes all children sprites from this sprite.
	 */
	public function removeAll():Void
	{
		for (child in children)
			remove(child);
	}

	override public function draw():Void
	{
		super.draw();

		for (child in children)
		{
			if (child.exists && child.visible)
				child.draw();
		}
	}
	override function drawSimple(camera:FlxCamera)
	{
		if (_parent != null)
			_point.addPoint(_parent._point);

		if (isPixelPerfectRender(camera))
			_point.floor();

		_point.copyToFlash(_flashPoint);
		camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, relativeColorTransform, blend, antialiasing);
	}
	public function preUpdate(elapsed:Float):Void
	{
		#if FLX_DEBUG
		FlxBasic.activeCount++;
		#end

		last.set(x, y);

		for (child in children)
		{
			if (child.active && child.exists)
				child.preUpdate(elapsed);
		}
	}
	override public function update(elapsed:Float) 
	{
		preUpdate(elapsed);

		for (child in children)
		{
			if (child.active && child.exists)
				child.update(elapsed);
		}
		
		postUpdate(elapsed);
	}

	public function postUpdate(elapsed:Float)
	{
		updateAnimation(elapsed);
	}
	override function drawComplex(camera:FlxCamera)
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		if (_parent != null)
			_matrix.concat(_parent._matrix);
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		_point.add(origin.x, origin.y);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}

		camera.drawPixels(_frame, framePixels, _matrix, relativeColorTransform, blend, antialiasing, shader);
	}
	override public function setColorTransform(redMultiplier:Float = 1.0, greenMultiplier:Float = 1.0, blueMultiplier:Float = 1.0, alphaMultiplier:Float = 1.0, redOffset:Int = 0, greenOffset:Int = 0, blueOffset:Int = 0, alphaOffset:Int = 0) 
	{
		super.setColorTransform(redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier, redOffset, greenOffset, blueOffset, alphaOffset);

		concatRelativeColor();
	}
	override function updateColorTransform() 
	{
		super.updateColorTransform();

		concatRelativeColor();
	}

	function concatRelativeColor()
	{
		if (relativeColorTransform == null)
			relativeColorTransform = new ColorTransform();


		relativeColorTransform.setMultipliers(1, 1, 1, 1);
		relativeColorTransform.setOffsets(0, 0, 0, 0);

		if (_parent != null)
			relativeColorTransform.concat(_parent.relativeColorTransform);

		relativeColorTransform.concat(colorTransform);

		for (child in children)
		{
			child.concatRelativeColor();
		}
	}

	#if FLX_DEBUG
	override public function drawDebug():Void
	{
		super.drawDebug();

		for (child in children)
		{
			if (child.exists && child.visible)
				child.drawDebug();
		}
	}
	#end

	override function set_facing(Direction:Int):Int
	{
		super.set_facing(Direction);
		if (children != null)
		{
			for (child in children)
			{
				if (child.exists && child.active)
					child.facing = Direction;
			}
		}

		return Direction;
	}

	inline function get_count():Int
	{
		return children.length;
	}
}
