package flixel.addons.nape;

import flixel.FlxSprite;
import flixel.util.FlxAngle;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;

/**
 * FlxNapeSprite consists of an FlxSprite with a physics body.
 * During the simulation, the sprite follows the physics body position and rotation.
 * 
 * By default, a rectangular physics body is created upon construction in createRectangularBody().
 * 
 * @author TiagoLr ( ~~~ProG4mr~~~ )
 */
class FlxNapeSprite extends FlxSprite
{
	/**
	 * body is the physics body associated with this sprite. 
	 */
	public var body:Body;
	
	/**
	 * Enables/Disables this sprites physics body in simulations.
	 */
	public var physicsEnabled(default, set):Bool = false;
	
	/**
	 * Internal var to update body.velocity.x and body.velocity.y. 
	 * Default is 1, which menas no drag.
	 */
	private var _linearDrag:Float = 1;
	/**
	 * Internal var to update body.angularVel
	 * Default is 1, which menas no drag.
	 */
	private var _angularDrag:Float = 1;

	/**
	 * Creates an FlxNapeSprite with an optional physics body (body).
	 * At each step, the physics are updated, and so is the position and rotation of the sprite 
	 * to match the bodys position and rotation values.
	 * By default a physics body with rectangle shape will be created around your sprite graphics.
	 * You can override this functionality and add a premade body of your own (see addPremadeBody).
	 * 
	 * @param	X						The initial X position of the sprite.
	 * @param	Y						The initial Y position of the sprite.
	 * @param	SimpleGraphic 			The graphic you want to display (OPTIONAL - for simple stuff only, do NOT use for animated images!).
	 * @param	CreateRectangularBody	Whether to create a rectangular body for this sprite (use false if you want to add a custom body).
	 * @param	EnablePhysics			Whether to enable physics simulation on the rectangular body (only relevant if CreateRectangularBody == true).
	 */
	public function new(X:Float = 0, Y:Float = 0, ?SimpleGraphic:Dynamic, CreateRectangularBody:Bool = true, EnablePhysics:Bool = true) 
	{
		super(X, Y, SimpleGraphic);
		
		if (CreateRectangularBody)
		{
			createRectangularBody();
			physicsEnabled = EnablePhysics;
		}
	}

	/**
	 * WARNING: This will remove this sprite entirely. Use kill() if you 
	 * want to disable it temporarily only and reset() it later to revive it.
	 * Override this function to null out variables or manually call
	 * destroy() on class members if necessary.
	 * Don't forget to call super.destroy()!
	 */
	override public function destroy():Void 
	{
		destroyPhysObjects();
		
		super.destroy();
	}

	/**
	 * Override core physics velocity etc
	 */
	override public function update():Void
	{
		super.update();
		
		if ((body != null) && moves)
		{
			updatePhysObjects();
		}
	}

	/**
	 * Handy function for "killing" game objects.
	 * Default behavior is to flag them as nonexistent AND dead.
	 */
	override public function kill():Void
	{
		super.kill();
		
		if (body != null)
		{
			body.space = null;
		}
	}

	/**
	 * Handy function for bringing game objects "back to life". Just sets alive and exists back to true.
	 * In practice, this function is most often called by FlxObject.reset().
	 */
	override public function revive():Void
	{
		super.revive();
		
		if (body != null)
		{
			body.space = FlxNapeState.space;
		}
	}
	
	/**
	 * Makes it easier to add a physics body of your own to this sprite by setting it's position,
	 * space and material for you.
	 * 
	 * @param	NewBody 	The new physics body replacing the old one.
	 */
	public function addPremadeBody(NewBody:Body):Void
	{
		var currSpace:Space = null;
		
		if (body != null) 
		{
			currSpace = body.space;
			destroyPhysObjects();
		}
		
		NewBody.position.x = x;
		NewBody.position.y = y;
		NewBody.space = currSpace;
		body = NewBody;
		setBodyMaterial();
	}
	
	/**
	 * Creates a circular physics body for this sprite.
	 * 
	 * @param	Radius	The radius of the circle-shaped body - 16 by default
	 * @param 	_Type	The BodyType of the physics body. Optional, DYNAMIC by default.
	 */
	public function createCircularBody(Radius:Float = 16, ?_Type:BodyType):Void
	{
		var currSpace:Space = null;
		
		if (body != null) 
		{
			currSpace = body.space;
			destroyPhysObjects();
		}
			
		centerOffsets(false);
		body = new Body(_Type != null ? _Type : BodyType.DYNAMIC, Vec2.weak(x, y));
		body.shapes.add(new Circle(Radius));
		body.space = currSpace;
		
		setBodyMaterial();
	}
	
	/**
	 * Default method to create the physics body used by this sprite in shape of a rectangle.
	 * Override this method to create your own physics body!
	 * The width and height used are based on the size of sprite graphics if 0 is passed.
	 * Call this method after calling makeGraphics() or loadGraphic() to update the body size.
	 * 
	 * @param	Width	The width of the rectangle. 0 = frameWidth
	 * @param	Height	The height of the rectangle. 0 = frameHeight
	 * @param	_Type	The BodyType of the physics body. Optional, DYNAMIC by default.
	 */
	public function createRectangularBody(Width:Float = 0, Height:Float = 0, ?_Type:BodyType):Void
	{
		var currSpace:Space = null;
		
		if (body != null) 
		{
			currSpace = body.space;
			destroyPhysObjects();
		}
		
		if (Width == 0)
		{
			Width = frameWidth;
		}
		if (Height == 0)
		{
			Height = frameHeight;
		}
		
		centerOffsets(false);
		body = new Body(_Type != null ? _Type : BodyType.DYNAMIC, Vec2.weak(x, y));
		body.shapes.add(new Polygon(Polygon.box(Width, Height)));
		body.space = currSpace;
		
		setBodyMaterial();
	}
	
	/**
	 * Shortcut method to set/change the physics body material.
	 * 
	 * @param	Elasticity			Elasticity of material.		
	 * @param	DynamicFriction		Coeffecient of dynamic friction for material.
	 * @param	StaticFriction		Coeffecient of static friction for material.
	 * @param	Density				Density of this Material.
	 * @param	RotationFriction	Coeffecient of rolling friction for circle interactions.
	 */
	public function setBodyMaterial(Elasticity:Float = 1, DynamicFriction:Float = 0.2, StaticFriction:Float = 0.4, Density:Float = 1, RotationFriction:Float = 0.001):Void
	{
		if (body == null) 
		{
			return;
		}
		
		body.setShapeMaterials(new Material(Elasticity, DynamicFriction, StaticFriction, Density, RotationFriction));
	}
	
	/**
	 * Destroys the physics main body.
	 */
	public function destroyPhysObjects():Void
	{
		if (body != null) 
		{
			FlxNapeState.space.bodies.remove(body);
			body = null;
		}
	}

	/**
	 * Nape requires fluid spaces to add empty space linear drag and angular drag.
	 * This provides a simple drag alternative. 
	 * Set any values to linearDrag or angularDrag to activate this feature for this object.
	 * 
	 * @param	LinearDrag		Typical value 0.96 (1 = no drag).
	 * @param	AngularDrag		Typical value 0.96 (1 = no drag);
	 */
	public inline function setDrag(LinearDrag:Float = 1, AngularDrag:Float = 1):Void
	{
		_linearDrag	= LinearDrag;
		_angularDrag = AngularDrag;
	}
	
	#if !FLX_NO_DEBUG
	/**
	 * Hide debug outline on physics sprites if the physics debug shapes are turned on
	 */	
	override public function drawDebug():Void
	{
		if (FlxNapeState.debug == null)
		{
			super.drawDebug();
		}
	}
	#end
	
	/**
	 * Updates physics FlxSprite graphics to follow this sprite physics object, called at the end of update().
	 * Things that are updated: Position, angle, angular and linear drag.
	 */	
	private function updatePhysObjects():Void 
	{
		x = body.position.x - origin.x;
		y = body.position.y - origin.y;
		
		if (body.allowRotation)
		{
			angle = body.rotation * FlxAngle.TO_DEG;
		}
		
		// Applies custom physics drag.
		if (_linearDrag < 1 || _angularDrag < 1) 
		{
			body.angularVel *= _angularDrag;
			body.velocity.x *= _linearDrag;
			body.velocity.y *= _linearDrag;
		}
	}
	
	private inline function set_physicsEnabled(Value:Bool):Bool
	{
		body.space = Value ? FlxNapeState.space : null;
		return physicsEnabled = Value;
	}
}