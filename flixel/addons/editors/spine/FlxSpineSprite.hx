package flixel.addons.editors.spine;

import openfl.Assets;
import haxe.ds.ObjectMap;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.util.loaders.SpriteSheetRegion;
import flixel.system.frontEnds.BitmapFrontEnd.CachedGraphicsObject;

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
import spinehx.platform.nme.BitmapDataTexture;
import spinehx.platform.nme.BitmapDataTextureLoader;
import spinehx.platform.nme.renderers.SkeletonRenderer;
import spinehx.platform.nme.renderers.SkeletonRendererDebug;

/**
 * A Sprite that can play animations exported by Spine (http://esotericsoftware.com/)
 * 
 * @author Big thanks to the work on spinehx by nitrobin (https://github.com/nitrobin/spinehx).
 * HaxeFlixel Port by: Sasha (Beeblerox), Sam Batista (crazysam), Kuris Makku (xraven13)
 */
class FlxSpineSprite extends FlxSprite
{
	public var skeleton:Skeleton;
	public var skeletonData:SkeletonData;
	public var state:AnimationState;
	public var stateData:AnimationStateData;
	
	public var renderer:SkeletonRenderer;
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
		skeleton.setX(X);
		skeleton.setY(Y);
		skeleton.setFlipY(true);
		//skeleton.setFlipX(true);
		
		renderer = new SkeletonRenderer(skeleton);
		renderer.visible = false;
		
		wrapperAngles = new ObjectMap<RegionAttachment, Float>();
		cachedSprites = new ObjectMap<RegionAttachment, FlxSprite>();
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
		var spineAtlas:TextureAtlas = TextureAtlas.create(Assets.getText(DataPath + DataName + ".atlas"), DataPath, new BitmapDataTextureLoader());
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
		
		_aabb.set(0,0,0,0);
		
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
				
				wrapper.x = bone.worldX + x * bone.m00 + y * bone.m01 + this.x - wrapper.frameWidth * 0.5;
				wrapper.y = bone.worldY + x * bone.m10 + y * bone.m11 + this.y - wrapper.frameHeight * 0.5;
				
				wrapper.angle = (-(bone.worldRotation + regionAttachment.rotation) + wrapperAngle) * flip;
				wrapper.scale.x = (bone.worldScaleX + regionAttachment.scaleX - 1) * flipX;
				wrapper.scale.y = (bone.worldScaleY + regionAttachment.scaleY - 1) * flipY;
				wrapper.antialiasing = antialiasing;
				wrapper.visible = true;
				wrapper.draw();
				
				if (_aabb.width == 0 && _aabb.height == 0)
				{
					_aabb.copyFrom(wrapper.aabb);
				}
				else
				{
					_aabb.union(wrapper.aabb);
				}
			}
		}
		
		collider.x = _aabb.x;
		collider.y = _aabb.y;
		collider.width = _aabb.width;
		collider.height = _aabb.height;
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
		var texture:BitmapDataTexture = cast region.getTexture();
		
		var cachedGraphic:CachedGraphicsObject = FlxG.bitmap.add(texture.bd);
		var atlasRegion:SpriteSheetRegion = new SpriteSheetRegion(cachedGraphic, region.getRegionX(), region.getRegionY());
		
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