package flixel.addons.editors.spine;

import flixel.addons.editors.spine.texture.FlixelTexture;
import flixel.addons.editors.spine.texture.FlixelTextureLoader;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import haxe.ds.ObjectMap;
import openfl.Assets;
import openfl.display.BlendMode;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.atlas.TextureAtlas;
import spinehaxe.attachments.Attachment;
import spinehaxe.attachments.RegionAttachment;
import spinehaxe.Bone;
import spinehaxe.Skeleton;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.Slot;

/**
 * A Sprite that can play animations exported by Spine (http://esotericsoftware.com/)
 * 
 * @author Big thanks to the work on spinehaxe by nitrobin (https://github.com/nitrobin/spinehx).
 * HaxeFlixel Port by: Sasha (Beeblerox), Sam Batista (crazysam), Kuris Makku (xraven13)
 * 
 * Current version is working with https://github.com/bendmorris/spinehaxe
 * since original lib by nitrobin isn't supported anymore.
 */
class FlxSpine extends FlxSprite
{
	/**
	 * Get Spine animation data.
	 * 
	 * @param	DataName	The name of the animation data files exported from Spine (.atlas .json .png).
	 * @param	DataPath	The directory these files are located at
	 * @param	Scale		Animation scale
	 */
	public static function readSkeletonData(DataName:String, DataPath:String, Scale:Float = 1):SkeletonData
	{
		if (DataPath.lastIndexOf("/") < 0) DataPath += "/"; // append / at the end of the folder path
		var spineAtlas:TextureAtlas = TextureAtlas.create(Assets.getText(DataPath + DataName + ".atlas"), DataPath, new FlixelTextureLoader());
		var json:SkeletonJson = SkeletonJson.create(spineAtlas);
		json.scale = Scale;
		var skeletonData:SkeletonData = json.readSkeletonData(Assets.getText(DataPath + DataName + ".json"), DataName);
		return skeletonData;
	}
	
	public var skeleton:Skeleton;
	public var skeletonData:SkeletonData;
	public var state:AnimationState;
	public var stateData:AnimationStateData;
	
	// TODO: adjust collider's position
	public var collider:FlxObject;
	
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
		
		skeleton = new Skeleton(skeletonData);
		skeleton.x = 0;
		skeleton.y = 0;
		
		cachedSprites = new ObjectMap<RegionAttachment, FlxSprite>();
		
		skeleton.flipX = false;
		skeleton.flipY = true;
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
	
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		state.update(elapsed);
		state.apply(skeleton);
		skeleton.updateWorldTransform();
	}
	
	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		var flipX:Int = skeleton.flipX ? -1 : 1;
		var flipY:Int = skeleton.flipY ? 1 : -1;
		var flip:Int = flipX * flipY;
		
		var drawOrder:Array<Slot> = skeleton.drawOrder;
		var i:Int = 0, n:Int = drawOrder.length;
		
		while (i < n) 
		{
			var slot:Slot = drawOrder[i];
			if (slot.attachment == null)
			{
				i++;
				continue;
			}
			
			var regionAttachment:RegionAttachment = cast slot.attachment;
			if (regionAttachment != null) 
			{
				var wrapper:FlxSprite = get(regionAttachment);
				wrapper.blend = slot.data.additiveBlending ? BlendMode.ADD : BlendMode.NORMAL;
				
				wrapper.color = FlxColor.fromRGBFloat(skeleton.r * slot.r * regionAttachment.r,
				                                      skeleton.g * slot.g * regionAttachment.g,
												      skeleton.b * slot.b * regionAttachment.b);
				
				wrapper.alpha = skeleton.a * slot.a * regionAttachment.a;
				
				var bone:Bone = slot.bone;
				
				var wrapperAngle:Float = wrapper.angle;
				var wrapperScaleX:Float = wrapper.scale.x;
				var wrapperScaleY:Float = wrapper.scale.y;
				
				var wrapperOriginX:Float = wrapper.origin.x;
				var wrapperOriginY:Float = wrapper.origin.y;
				
				var worldRotation:Float = -bone.worldRotation;
				var worldScaleX:Float = bone.worldScaleX;
				var worldScaleY:Float = bone.worldScaleY;
				
				wrapper.origin.set(0, 0);
				
				_matrix.identity();
				_matrix.translate(wrapperOriginX, wrapperOriginY);
				_matrix.scale(worldScaleX, worldScaleY);
				_matrix.rotate(worldRotation * Math.PI / 180);
				
				wrapper.angle += worldRotation;
				wrapper.angle *= flip;
				wrapper.scale.x *= worldScaleX * flipX;
				wrapper.scale.y *= worldScaleY * flipY;
				
				wrapper.x = this.x + bone.worldX + _matrix.tx * flipX;
				wrapper.y = this.y + bone.worldY + _matrix.ty * flipY;
				
				wrapper.antialiasing = antialiasing;
				wrapper.visible = true;
				wrapper.draw();
				
				wrapper.angle = wrapperAngle;
				wrapper.scale.set(wrapperScaleX, wrapperScaleY);
				wrapper.origin.set(wrapperOriginX, wrapperOriginY);
			}	
			
			i++;
		}
	}
	
	#if !FLX_NO_DEBUG
	override public function drawDebugOnCamera(Camera:FlxCamera):Void
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
	#end
	
	public function get(regionAttachment:RegionAttachment):FlxSprite 
	{
		if (cachedSprites.exists(regionAttachment))
			return cachedSprites.get(regionAttachment);
		
		var region:AtlasRegion = cast regionAttachment.region;
		var texture:FlixelTexture = cast region.texture;
		
		var regionWidth:Float = region.rotate ? region.regionHeight : region.regionWidth;
		var regionHeight:Float = region.rotate ? region.regionWidth : region.regionHeight;
		
		var graph:FlxGraphic = FlxG.bitmap.add(texture.bd);
		var atlasFrames:FlxAtlasFrames = (graph.atlasFrames == null) ? new FlxAtlasFrames(graph) : graph.atlasFrames;
		
		var name:String = region.name;
		var offset:FlxPoint = FlxPoint.get(0, 0);
		var frameRect:FlxRect = new FlxRect(region.regionX, region.regionY, region.regionWidth, region.regionHeight);
		
		var sourceSize:FlxPoint = FlxPoint.get(frameRect.width, frameRect.height);
		var imageFrame = FlxImageFrame.fromFrame(atlasFrames.addAtlasFrame(frameRect, sourceSize, offset, name));
		
		var wrapper:FlxSprite = new FlxSprite();
		wrapper.frames = imageFrame;
		wrapper.antialiasing = antialiasing;
		
		wrapper.angle = -regionAttachment.rotation;
		wrapper.scale.x = regionAttachment.scaleX * (regionAttachment.width / regionWidth);
		wrapper.scale.y = regionAttachment.scaleY * (regionAttachment.height / regionHeight);

		// Position using attachment translation, shifted as if scale and rotation were at image center.
		var radians:Float = -regionAttachment.rotation * Math.PI / 180;
		var cos:Float = Math.cos(radians);
		var sin:Float = Math.sin(radians);
		var shiftX:Float = -regionAttachment.width / 2 * regionAttachment.scaleX;
		var shiftY:Float = -regionAttachment.height / 2 * regionAttachment.scaleY;
		
		if (region.rotate) 
		{
			wrapper.angle += 90;
			shiftX += regionHeight * (regionAttachment.width / region.regionWidth);
		}
		
		wrapper.origin.x = regionAttachment.x + shiftX * cos - shiftY * sin;
		wrapper.origin.y = -regionAttachment.y + shiftX * sin + shiftY * cos;
		
		cachedSprites.set(regionAttachment, wrapper);
		return wrapper;
	}
}