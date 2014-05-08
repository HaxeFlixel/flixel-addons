package flixel.addons.display;

import flash.geom.ColorTransform;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.util.FlxAngle;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPoint;
import flixel.util.FlxVelocity;

/**
 * Some sort of DisplayObjectContainer but very limited.
 * It can contain only other FlxNestedSprites.
 * @author Zaphod
 */
class FlxNestedSprite extends FlxSprite
{
	/**
	 * X position of this sprite relative to parent, 0 by default
	 */
	public var relativeX:Float = 0;
	/**
	 * Y position of this sprite relative to parent, 0 by default
	 */
	public var relativeY:Float = 0;
	
	/**
	 * Angle of this sprite relative to parent
	 */
	public var relativeAngle:Float = 0;

	/**
	 * Angular velocity relative to parent sprite
	 */
	public var relativeAngularVelocity:Float = 0;

	/**
	 * Angular acceleration relative to parent sprite
	 */
	public var relativeAngularAcceleration:Float = 0;
	
	public var relativeAlpha:Float = 1;
	
	/**
	 * Scale of this sprite relative to parent
	 */
	public var relativeScale(default, null):FlxPoint;
	
	/**
	 * Velocity relative to parent sprite
	 */
	public var relativeVelocity(default, null):FlxPoint;
	
	/**
	 * Acceleration relative to parent sprite
	 */
	public var relativeAcceleration(default, null):FlxPoint;
	
	/**
	 * All FlxNestedSprites in this list.
	 */
	public var children(default, null):Array<FlxNestedSprite>;
	
	/**
	 * Amount of Graphics in this list.
	 */
	public var count(get, never):Int;
	
	private var _parentRed:Float = 1;
	private var _parentGreen:Float = 1;
	private var _parentBlue:Float = 1;
	
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic) 
	{
		super(X, Y, SimpleGraphic);
		children = [];
		relativeScale = FlxPoint.get(1, 1);
		relativeVelocity = FlxPoint.get();
		relativeAcceleration = FlxPoint.get();
	}
	
	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you 
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Used to clean up memory.
	 */
	override public function destroy():Void
	{
		super.destroy();
		
		relativeScale = FlxDestroyUtil.put(relativeScale);
		relativeVelocity = FlxDestroyUtil.put(relativeVelocity);
		relativeAcceleration = FlxDestroyUtil.put(relativeAcceleration);
		
		if (children != null)
		{
			for (child in children)
			{
				child.destroy();
			}
			
			children = null;
		}
	}
	
	/**
	 * Adds the FlxNestedSprite to the children list.
	 * 
	 * @param	Child	The FlxNestedSprite to add.
	 * @return	The added FlxNestedSprite.
	 */
	public function add(Child:FlxNestedSprite):FlxNestedSprite
	{
		if (children.indexOf(Child) < 0)
		{
			children.push(Child);
			Child.velocity.x = Child.velocity.y = 0;
			Child.acceleration.x = Child.acceleration.y = 0;
			Child.scrollFactor.x = scrollFactor.x;
			Child.scrollFactor.y = scrollFactor.y;
			
			Child.alpha = Child.relativeAlpha * alpha;

			var thisRed:Float = (color >> 16) / 255;
			var thisGreen:Float = (color >> 8 & 0xff) / 255;
			var thisBlue:Float = (color & 0xff) / 255;
			
			Child._parentRed = thisRed;
			Child._parentGreen = thisGreen;
			Child._parentBlue = thisBlue;
			Child.color = Child.color;
		}
		
		return Child;
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
		{
			children.splice(index, 1);
		}
		
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
		{
			return null;
		}
		
		return remove(children[Index]);
	}
	
	/**
	 * Removes all children sprites from this sprite.
	 */
	public function removeAll():Void
	{
		for (child in children)
		{
			remove(child);
		}
	}
	
	public function preUpdate():Void 
	{
		#if !FLX_NO_DEBUG
		FlxBasic._ACTIVECOUNT++;
		#end
		
		last.x = x;
		last.y = y;
		
		for (child in children)
		{
			if (child.active && child.exists)
			{
				child.preUpdate();
			}
		}
	}
	
	override public function update():Void 
	{
		preUpdate();
		
		for (child in children)
		{
			if (child.active && child.exists)
			{
				child.update();
			}
		}
		
		postUpdate();
	}
	
	public function postUpdate():Void 
	{
		if (moves)
		{
			updateMotion();
		}
		
		wasTouching = touching;
		touching = FlxObject.NONE;
		animation.update();
		
		
		var delta:Float;
		var velocityDelta:Float;
		var dt:Float = FlxG.elapsed;
		
		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeAngularVelocity, relativeAngularAcceleration, angularDrag, maxAngular) - relativeAngularVelocity);
		relativeAngularVelocity += velocityDelta; 
		relativeAngle += relativeAngularVelocity * dt;
		relativeAngularVelocity += velocityDelta;
		
		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeVelocity.x, relativeAcceleration.x, drag.x, maxVelocity.x) - relativeVelocity.x);
		relativeVelocity.x += velocityDelta;
		delta = relativeVelocity.x * dt;
		relativeVelocity.x += velocityDelta;
		relativeX += delta;
		
		velocityDelta = 0.5 * (FlxVelocity.computeVelocity(relativeVelocity.y, relativeAcceleration.y, drag.y, maxVelocity.y) - relativeVelocity.y);
		relativeVelocity.y += velocityDelta;
		delta = relativeVelocity.y * dt;
		relativeVelocity.y += velocityDelta;
		relativeY += delta;
		
		
		for (child in children)
		{
			if (child.active && child.exists)
			{
				child.velocity.x = child.velocity.y = 0;
				child.acceleration.x = child.acceleration.y = 0;
				child.angularVelocity = child.angularAcceleration = 0;
				child.postUpdate();
				
				if (isSimpleRender(camera))
				{
					child.x = x + child.relativeX - offset.x;
					child.y = y + child.relativeY - offset.y;
				}
				else
				{
					var radians:Float = angle * FlxAngle.TO_RAD;
					var cos:Float = Math.cos(radians);
					var sin:Float = Math.sin(radians);
					
					var dx:Float = child.relativeX - offset.x;
					var dy:Float = child.relativeY - offset.y;
					
					var relX:Float = (dx * cos * scale.x - dy * sin * scale.y);
					var relY:Float = (dx * sin * scale.x + dy * cos * scale.y);
					
					child.x = x + relX;
					child.y = y + relY;
				}
				
				child.angle = angle + child.relativeAngle;
				child.scale.x = scale.x * child.relativeScale.x;
				child.scale.y = scale.y * child.relativeScale.y;
				
				child.velocity.x = velocity.x;
				child.velocity.y = velocity.y;
				child.acceleration.x = acceleration.x;
				child.acceleration.y = acceleration.y;
			}
		}
	}
	
	override public function draw():Void 
	{
		super.draw();
		
		for (child in children)
		{
			if (child.exists && child.visible)
			{
				child.draw();
			}
		}
	}
	
	#if !FLX_NO_DEBUG
	override public function drawDebug():Void 
	{
		super.drawDebug();
		
		for (child in children)
		{
			if (child.exists && child.visible)
			{
				child.drawDebug();
			}
		}
	}
	#end
	
	override private function set_alpha(Alpha:Float):Float
	{
		if (Alpha > 1)
		{
			Alpha = 1;
		}
		if (Alpha < 0)
		{
			Alpha = 0;
		}
		if (Alpha == alpha)
		{
			return alpha;
		}
		alpha = Alpha * relativeAlpha;
		
		#if FLX_RENDER_BLIT
		if ((alpha != 1) || (color != 0x00ffffff))
		{
			var red:Float = (color >> 16) * _parentRed / 255;
			var green:Float = (color >> 8 & 0xff) * _parentGreen / 255;
			var blue:Float = (color & 0xff) * _parentBlue / 255;
			
			if (colorTransform == null)
			{
				colorTransform = new ColorTransform(red, green, blue, alpha);
			}
			else
			{
				colorTransform.redMultiplier = red;
				colorTransform.greenMultiplier = green;
				colorTransform.blueMultiplier = blue;
				colorTransform.alphaMultiplier = alpha;
			}
			useColorTransform = true;
		}
		else
		{
			if (colorTransform != null)
			{
				colorTransform.redMultiplier = 1;
				colorTransform.greenMultiplier = 1;
				colorTransform.blueMultiplier = 1;
				colorTransform.alphaMultiplier = 1;
			}
			useColorTransform = false;
		}
		dirty = true;
		#end
		
		if (children != null)
		{
			for (child in children)
			{
				child.alpha = alpha;
			}
		}
		
		return alpha;
	}
	
	override private function set_color(Color:Int):Int
	{
		Color &= 0x00ffffff;
		
		var combinedRed:Float = (Color >> 16) * _parentRed / 255;
		var combinedGreen:Float = (Color >> 8 & 0xff) * _parentGreen / 255;
		var combinedBlue:Float = (Color & 0xff) * _parentBlue / 255;
		
		var combinedColor:Int = Std.int(combinedRed * 255) << 16 | Std.int(combinedGreen * 255) << 8 | Std.int(combinedBlue * 255);
		
		if (color == combinedColor)
		{
			return color;
		}
		color = combinedColor;
		if ((alpha != 1) || (color != 0x00ffffff))
		{
			if (colorTransform == null)
			{
				colorTransform = new ColorTransform(combinedRed, combinedGreen, combinedBlue, alpha);
			}
			else
			{
				colorTransform.redMultiplier = combinedRed;
				colorTransform.greenMultiplier = combinedGreen;
				colorTransform.blueMultiplier = combinedBlue;
				colorTransform.alphaMultiplier = alpha;
			}
			useColorTransform = true;
		}
		else
		{
			if (colorTransform != null)
			{
				colorTransform.redMultiplier = 1;
				colorTransform.greenMultiplier = 1;
				colorTransform.blueMultiplier = 1;
				colorTransform.alphaMultiplier = 1;
			}
			useColorTransform = false;
		}
		
		dirty = true;
		
		#if FLX_RENDER_TILE
		_red = combinedRed;
		_green = combinedGreen;
		_blue = combinedBlue;
		#end
		
		for (child in children)
		{
			var childColor:Int = child.color;
			
			var childRed:Float = (childColor >> 16) / (255 * child._parentRed);
			var childGreen:Float = (childColor >> 8 & 0xff) / (255 * child._parentGreen);
			var childBlue:Float = (childColor & 0xff) / (255 * child._parentBlue);
			
			combinedColor = Std.int(childRed * combinedRed * 255) << 16 | Std.int(childGreen * combinedGreen * 255) << 8 | Std.int(childBlue * combinedBlue * 255);
			
			child.color = combinedColor;
			
			child._parentRed = combinedRed;
			child._parentGreen = combinedGreen;
			child._parentBlue = combinedBlue;
		}
		
		return color;
	}
	
	override private function set_facing(Direction:Int):Int
	{
		super.set_facing(Direction);
		if (children != null)
		{
			for (child in children)
			{
				if (child.exists && child.active)
				{
					child.facing = Direction;
				}
			}
		}
		return Direction;
	}
	
	private inline function get_count():Int 
	{ 
		return children.length; 
	}
}