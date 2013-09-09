package flixel.addons.editors.spine;

import openfl.Assets;
import haxe.ds.ObjectMap;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.FlxAngle;
import flixel.util.loaders.CachedGraphics;
import flixel.util.loaders.TextureRegion;

import flixel.addons.editors.spine.texture.FlixelTexture;
import flixel.addons.editors.spine.texture.FlixelTextureLoader;

import spinehx.Bone;
import spinehx.Slot;
import spinehx.Skeleton;
import spinehx.SkeletonData;
import spinehx.SkeletonJson;
import spinehx.AnimationState;
import spinehx.AnimationStateData;
import spinehx.atlas.TextureAtlas;
import spinehx.attachments.Attachment;
import spinehx.attachments.RegionAttachment;

/**
 * A Sprite that can play animations exported by Spine (http://esotericsoftware.com/)
 * 
 * @author Big thanks to the work on spinehx by nitrobin (https://github.com/nitrobin/spinehx).
 * HaxeFlixel Port by: Sasha (Beeblerox), Sam Batista (crazysam), Kuris Makku (xraven13)
 */
class FlxSpine extends FlxSprite
{
	public var skeleton:Skeleton;
	public var skeletonData:SkeletonData;
	public var state:AnimationState;
	public var stateData:AnimationStateData;
	
	// TODO: adjust collider's position
	public var collider:FlxObject;
	
	public var wrapperAngles:ObjectMap<RegionAttachment, Float>;
	public var cachedSprites:ObjectMap<RegionAttachment, FlxSprite>;
	
	/**
	 * Instantiate a new Spine Sprite.
	 * @param	skeletonData	Animation data from Spine (.json .skel .png), get it like this: FlxSpineSprite.readSkeletonData( "mySpriteData", "assets/" );
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	Width			The maximum width of this sprite (avoid very large sprites since they are performance intensive).
	 * @param	Height			The maximum height of this sprite (avoid very large sprites since they are performance intensive).
	 */
	public function new(skeletonData:SkeletonData, X:Float = 0, Y:Float = 0) 
	{
		super(X, Y);
		
		collider = new FlxObject(X, Y);
		
		width = 0;
		height = 0;
		
		this.skeletonData = skeletonData;
		
		stateData = new AnimationStateData(skeletonData);
		state = new AnimationState(stateData);
		
		skeleton = Skeleton.create(skeletonData);
		skeleton.setX(0);
		skeleton.setY(0);
		skeleton.setFlipY(true);
		//skeleton.setFlipX(true);
		
		cachedSprites = new ObjectMap<RegionAttachment, FlxSprite>();
		wrapperAngles = new ObjectMap<RegionAttachment, Float>();
	}
	
	override public function destroy():Void
	{
		if (collider != null)
			collider.destroy();
		collider = null;
		
		skeletonData = null;
		skeleton = null;
		state = null;
		stateData = null;
		wrapperAngles = null;
		
		if (cachedSprites != null)
		{
			for (key in cachedSprites.keys())
			{
				var sprite:FlxSprite = cachedSprites.get(key);
				cachedSprites.remove(key);
				if (sprite != null)	
					sprite.destroy();
			}
		}
		cachedSprites = null;
		
		super.destroy();
	}
	
	public var flipX(get, set):Bool;
	
	private function get_flipX():Bool
	{
		return skeleton.flipX;
	}
	
	private function set_flipX(value:Bool):Bool
	{
		if (value != skeleton.flipX)
			skeleton.setFlipX(value);
			
		facing = (value == true) ? FlxObject.LEFT : FlxObject.RIGHT;
		return value;
	}
	
	public var flipY(get, set):Bool;
	
	private function get_flipY():Bool
	{
		return skeleton.flipY;
	}
	
	private function set_flipY(value:Bool):Bool
	{
		if (value != skeleton.flipY)
			skeleton.setFlipY(value);
			
		return value;
	}
	
	/**
	 * Get Spine animation data.
	 * @param	DataName	The name of the animation data files exported from Spine (.atlas .json .png).
	 * @param	DataPath	The directory these files are located at
	 * @param	Scale		Animation scale
	 */
	public static function readSkeletonData(DataName:String, DataPath:String, Scale:Float = 1):SkeletonData
	{
		if (DataPath.lastIndexOf("/") < 0) DataPath += "/"; // append / at the end of the folder path
		var spineAtlas:TextureAtlas = TextureAtlas.create(Assets.getText(DataPath + DataName + ".atlas"), DataPath, new FlixelTextureLoader());
		var json:SkeletonJson = SkeletonJson.create(spineAtlas);
		json.setScale(Scale);
		var skeletonData:SkeletonData = json.readSkeletonData(DataName, Assets.getText(DataPath + DataName + ".json"));
		return skeletonData;
	}
	
	override public function update():Void
	{
		super.update();
		
		state.update(FlxG.elapsed * FlxG.timeScale);
		state.apply(skeleton);
		skeleton.updateWorldTransform();
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		var drawOrder:Array<Slot> = skeleton.drawOrder;
		var flipX:Int = (skeleton.flipX) ? -1 : 1;
		var flipY:Int = (skeleton.flipY) ? 1 : -1;
		var flip:Int = flipX * flipY;
		
		var skeletonX:Float = skeleton.getX();
		var skeletonY:Float = skeleton.getY();
		
		var radians:Float = angle * FlxAngle.TO_RAD;
		var cos:Float = Math.cos(radians);
		var sin:Float = Math.sin(radians);
		
		var oox:Float = origin.x + offset.x;
		var ooy:Float = origin.y + offset.y;
		
		for (slot in drawOrder) 
		{
			var attachment:Attachment = slot.attachment;
			if (Std.is(attachment, RegionAttachment)) 
			{
				var regionAttachment:RegionAttachment = cast attachment;
				regionAttachment.updateVertices(slot);
				var vertices = regionAttachment.getVertices();
				var wrapper:FlxSprite = get(regionAttachment);
				var wrapperAngle:Float = wrapperAngles.get(regionAttachment);
				var region:AtlasRegion = cast regionAttachment.getRegion();
				var bone:Bone = slot.getBone();
				var x:Float = regionAttachment.x - region.offsetX;
				var y:Float = regionAttachment.y - region.offsetY;
				
				var dx:Float = skeletonX + bone.worldX + x * bone.m00 + y * bone.m01 - oox;
				var dy:Float = skeletonY + bone.worldY + x * bone.m10 + y * bone.m11 - ooy;
				
				var relX:Float = (dx * cos * scale.x - dy * sin * scale.y);
				var relY:Float = (dx * sin * scale.x + dy * cos * scale.y);
				
				wrapper.x = this.x + relX - wrapper.frameWidth * 0.5;
				wrapper.y = this.y + relY - wrapper.frameHeight * 0.5;
				
				wrapper.angle = (-(bone.worldRotation + regionAttachment.rotation) + wrapperAngle) * flip + angle;
				wrapper.scale.x = (bone.worldScaleX + regionAttachment.scaleX - 1) * flipX * scale.x;
				wrapper.scale.y = (bone.worldScaleY + regionAttachment.scaleY - 1) * flipY * scale.y;
				wrapper.antialiasing = antialiasing;
				wrapper.visible = true;
				wrapper.draw();
			}
		}
	}
	
	override public function drawDebugOnCamera(Camera:FlxCamera = null):Void
	{
		super.drawDebugOnCamera(Camera);
		
		collider.drawDebugOnCamera(Camera);
		
		var drawOrder:Array<Slot> = skeleton.drawOrder;
		for (slot in drawOrder) 
		{
			var attachment:Attachment = slot.attachment;
			if (Std.is(attachment, RegionAttachment)) 
			{
				var regionAttachment:RegionAttachment = cast attachment;
				var wrapper:FlxSprite = get(regionAttachment);
				wrapper.drawDebugOnCamera(Camera);
			}
		}
	}
	
	public function get(regionAttachment:RegionAttachment):FlxSprite 
	{
		if (cachedSprites.exists(regionAttachment))
			return cachedSprites.get(regionAttachment);
		
		var region:AtlasRegion = cast regionAttachment.getRegion();
		var texture:FlixelTexture = cast region.getTexture();
		
		var cachedGraphic:CachedGraphics = FlxG.bitmap.add(texture.bd);
		var atlasRegion:TextureRegion = new TextureRegion(cachedGraphic, region.getRegionX(), region.getRegionY());
		
		if (region.rotate) 
		{
			atlasRegion.region.tileWidth = atlasRegion.region.width = region.getRegionHeight();
			atlasRegion.region.tileHeight = atlasRegion.region.height = region.getRegionWidth();
		}
		else 
		{
			atlasRegion.region.tileWidth = atlasRegion.region.width = region.getRegionWidth();
			atlasRegion.region.tileHeight = atlasRegion.region.height = region.getRegionHeight();
		}
		
		var wrapper:FlxSprite = new FlxSprite(0, 0, atlasRegion);
		wrapper.antialiasing = antialiasing;
		wrapper.origin.x = regionAttachment.width / 2; // Registration point.
		wrapper.origin.y = regionAttachment.height / 2;
		if (region.rotate) 
		{
			wrapper.angle = 90;
			wrapper.origin.x -= region.getRegionWidth();
		}
		
		cachedSprites.set(regionAttachment, wrapper);
		wrapperAngles.set(regionAttachment, wrapper.angle);
		return wrapper;
	}
}