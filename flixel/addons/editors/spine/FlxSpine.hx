package flixel.addons.editors.spine;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxStrip;
import flixel.addons.editors.spine.texture.FlixelTextureLoader;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxImageFrame;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.ds.ObjectMap;
import openfl.Assets;
import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.display.Sprite;
import spinehaxe.Bone;
import spinehaxe.Skeleton;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.Slot;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.atlas.Atlas;
import spinehaxe.atlas.AtlasRegion;
import spinehaxe.attachments.AtlasAttachmentLoader;
import spinehaxe.attachments.Attachment;
import spinehaxe.attachments.MeshAttachment;
import spinehaxe.attachments.RegionAttachment;

/**
 * A Sprite that can play animations exported by Spine (http://esotericsoftware.com/)
 *
 * @author Big thanks to the work on spinehx by nitrobin (https://github.com/nitrobin/spinehx).
 * HaxeFlixel Port by: Sasha (Beeblerox), Sam Batista (crazysam), Kuris Makku (xraven13)
 *
 * The current version is using https://github.com/bendmorris/spinehaxe
 * since the original lib by nitrobin isn't supported anymore.
 */
class FlxSpine extends FlxSprite
{
	/**
	 * Get Spine animation data (atlas + animation).
	 *
	 * @param	AtlasName		The name of the atlas data files exported from Spine (.atlas and .png).
	 * @param	AnimationName	The name of the animation data file exported from Spine (.json).
	 * @param	DataPath		The directory these files are located at
	 * @param	Scale			Animation scale
	 */
	public static function readSkeletonData(AtlasName:String, AnimationName:String, DataPath:String, Scale:Float = 1):SkeletonData
	{
		if (DataPath.lastIndexOf("/") < 0)
			DataPath += "/"; // append / at the end of the folder path
		var spineAtlas:Atlas = new Atlas(Assets.getText(DataPath + AtlasName + ".atlas"), new FlixelTextureLoader(DataPath));
		var json:SkeletonJson = new SkeletonJson(new AtlasAttachmentLoader(spineAtlas));
		json.scale = Scale;
		var skeletonData:SkeletonData = json.readSkeletonData(Assets.getText(DataPath + AnimationName + ".json"), AnimationName);
		return skeletonData;
	}

	public var skeleton(default, null):Skeleton;
	public var skeletonData(default, null):SkeletonData;
	public var state(default, null):AnimationState;
	public var stateData(default, null):AnimationStateData;

	/**
	 * Helper FlxObject, which you can use for colliding with other flixel objects.
	 * Collider have additional offsetX and offsetY properties which helps you to adjust hitbox.
	 * Change of position of this sprite causes change of collider's position and vice versa.
	 * But you should apply velocity and acceleration to collider rather than to this spine sprite.
	 */
	public var collider(default, null):FlxSpineCollider;

	public var renderMeshes:Bool = false;

	var _tempVertices:Array<Float>;
	var _quadTriangles:Array<Int>;
	var _regionWrappers = new Map<RegionAttachment, FlxSprite>();

	/**
	 * Instantiate a new Spine Sprite.
	 * @param	skeletonData	Animation data from Spine (.json .skel .png), get it like this: FlxSpineSprite.readSkeletonData( "mySpriteData", "assets/" );
	 * @param	X				The initial X position of the sprite.
	 * @param	Y				The initial Y position of the sprite.
	 * @param	Width			The maximum width of this sprite (avoid very large sprites since they are performance intensive).
	 * @param	Height			The maximum height of this sprite (avoid very large sprites since they are performance intensive).
	 * @param	OffsetX			The X offset of the sprite.
	 * @param	OffsetY			The Y offset of the sprite.
	 * @param	renderMeshes	If true, then graphic will be rendered with drawTriangles(), if false (by default), then it will be rendered with drawTiles().
	 */
	public function new(skeletonData:SkeletonData, X:Float = 0, Y:Float = 0, Width:Float = 0, Height:Float = 0, OffsetX:Float = 0, OffsetY:Float = 0,
			renderMeshes:Bool = false)
	{
		super(X, Y);

		Bone.yDown = true;

		width = Width;
		height = Height;

		this.skeletonData = skeletonData;

		stateData = new AnimationStateData(skeletonData);
		state = new AnimationState(stateData);

		skeleton = new Skeleton(skeletonData);
		skeleton.updateWorldTransform();

		flipX = false;
		flipY = false;

		collider = new FlxSpineCollider(this, X, Y, Width, Height, OffsetX, OffsetY);

		setPosition(x, y);
		setSize(width, height);

		var drawOrder:Array<Slot> = skeleton.drawOrder;
		for (slot in drawOrder)
		{
			if (slot.attachment == null)
			{
				continue;
			}

			if ((slot.attachment is MeshAttachment))
			{
				renderMeshes = true;
				break;
			}
		}

		this.renderMeshes = renderMeshes;

		_tempVertices = new Array<Float>();

		_quadTriangles = new Array<Int>();
		_quadTriangles[0] = 0; // = Vector.fromArray([0, 1, 2, 2, 3, 0]);
		_quadTriangles[1] = 1;
		_quadTriangles[2] = 2;
		_quadTriangles[3] = 2;
		_quadTriangles[4] = 3;
		_quadTriangles[5] = 0;
	}

	override public function destroy():Void
	{
		collider = FlxDestroyUtil.destroy(collider);

		skeletonData = null;
		skeleton = null;
		state = null;
		stateData = null;

		_tempVertices = null;
		_quadTriangles = null;

		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		skeleton.update(elapsed);
		state.update(elapsed);
		state.apply(skeleton);
		skeleton.updateWorldTransform();
	}

	/**
	 * Called by game loop, updates then blits or renders current frame of animation to the screen
	 */
	override public function draw():Void
	{
		if (alpha == 0)
			return;

		if (renderMeshes)
			renderWithTriangles();
		else
			renderWithQuads();

		collider.draw();
	}

	function renderWithTriangles():Void
	{
		var drawOrder:Array<Slot> = skeleton.drawOrder;
		var n:Int = drawOrder.length;
		var graph:FlxGraphic = null;
		var wrapper:FlxStrip;
		var worldVertices:Array<Float> = _tempVertices;
		var triangles:Array<Int> = null;
		var uvtData:Array<Float> = null;
		var verticesLength:Int = 0;
		var numVertices:Int;

		var r:Float = 0, g:Float = 0, b:Float = 0, a:Float = 0;
		var wrapperColor:Int;

		for (i in 0...n)
		{
			var slot:Slot = drawOrder[i];
			if (slot.attachment != null)
			{
				wrapper = null;

				if ((slot.attachment is RegionAttachment))
				{
					var region:RegionAttachment = cast slot.attachment;
					verticesLength = 8;
					region.computeWorldVertices(0, 0, slot.bone, worldVertices);
					uvtData = region.uvs;
					triangles = _quadTriangles;

					if (_regionWrappers.exists(region))
					{
						wrapper = cast _regionWrappers[region];
					}
					else
					{
						var atlasRegion:AtlasRegion = cast region.rendererObject;
						var graphic:FlxGraphic = cast atlasRegion.page.rendererObject;
						wrapper = new FlxStrip(0, 0, graphic);
						_regionWrappers[region] = wrapper;
					}

					r = region.r;
					g = region.g;
					b = region.b;
					a = region.a;
				}
				else if ((slot.attachment is MeshAttachment))
				{
					var mesh:MeshAttachment = cast slot.attachment;
					verticesLength = mesh.vertices.length;
					mesh.computeWorldVertices(slot, worldVertices);
					uvtData = mesh.uvs;
					triangles = mesh.triangles;

					if ((mesh.rendererObject is FlxStrip))
					{
						wrapper = cast mesh.rendererObject;
					}
					else
					{
						var atlasRegion:AtlasRegion = cast mesh.rendererObject;
						var graphic:FlxGraphic = cast atlasRegion.page.rendererObject;
						wrapper = new FlxStrip(0, 0, graphic);
						mesh.rendererObject = wrapper;
					}

					r = mesh.r;
					g = mesh.g;
					b = mesh.b;
					a = mesh.a;
				}
				if (wrapper != null)
				{
					wrapper.x = 0;
					wrapper.y = 0;
					wrapper._cameras = _cameras;

					#if (flash || openfl >= "4.0.0")
					wrapper.vertices.length = verticesLength;
					for (i in 0...verticesLength)
					{
						wrapper.vertices[i] = worldVertices[i];
					}
					#else
					if (worldVertices.length - verticesLength > 0)
					{
						worldVertices.splice(verticesLength, worldVertices.length - verticesLength);
					}

					wrapper.vertices = worldVertices;
					#end

					wrapper.indices = Vector.ofArray(triangles);
					wrapper.uvtData = Vector.ofArray(uvtData);

					wrapperColor = FlxColor.fromRGBFloat(skeleton.r * slot.r * r * color.redFloat, skeleton.g * slot.g * g * color.greenFloat,
						skeleton.b * slot.b * b * color.blueFloat, 1);

					wrapper.color = wrapperColor;
					wrapper.alpha = skeleton.a * slot.a * a * alpha;

					wrapper.blend = (slot.data.blendMode == spinehaxe.BlendMode.additive) ? BlendMode.ADD : null;
					wrapper.draw();
				}
			}
		}
	}

	function renderWithQuads():Void
	{
		var flipX:Int = skeleton.flipX ? -1 : 1;
		var flipY:Int = skeleton.flipY ? -1 : 1;
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

			var regionAttachment:RegionAttachment = null;
			if ((slot.attachment is RegionAttachment))
				regionAttachment = cast slot.attachment;

			if (regionAttachment != null)
			{
				var wrapper:FlxSprite = getSprite(regionAttachment);
				wrapper.blend = (slot.data.blendMode == spinehaxe.BlendMode.additive) ? BlendMode.ADD : BlendMode.NORMAL;

				wrapper.color = FlxColor.fromRGBFloat(skeleton.r * slot.r * regionAttachment.r * color.redFloat,
					skeleton.g * slot.g * regionAttachment.g * color.greenFloat, skeleton.b * slot.b * regionAttachment.b * color.blueFloat);

				wrapper.alpha = skeleton.a * slot.a * regionAttachment.a * this.alpha;

				var bone:Bone = slot.bone;

				var wrapperAngle:Float = wrapper.angle;
				var wrapperScaleX:Float = wrapper.scale.x;
				var wrapperScaleY:Float = wrapper.scale.y;

				var wrapperOriginX:Float = wrapper.origin.x;
				var wrapperOriginY:Float = wrapper.origin.y;

				var worldRotation:Float = bone.worldRotationX;
				var worldScaleX:Float = bone.worldScaleX;
				var worldScaleY:Float = bone.worldScaleY;

				wrapper.origin.set(0, 0);

				_matrix.identity();
				_matrix.rotate(wrapperAngle * Math.PI / 180);
				_matrix.scale(wrapperScaleX, wrapperScaleY);
				_matrix.translate(wrapperOriginX, wrapperOriginY);
				_matrix.scale(worldScaleX * flipX, worldScaleY * flipY);
				_matrix.rotate(worldRotation * Math.PI / 180);
				if (flipX != 1)
					_matrix.rotate(Math.PI);

				wrapper.angle += worldRotation * flip;
				if (flipX != 1)
					wrapper.angle += 180;
				wrapper.angle *= flip;

				wrapper.scale.x *= (wrapperAngle == 0) ? worldScaleX : worldScaleY;
				wrapper.scale.x *= flipX;
				wrapper.scale.y *= (wrapperAngle == 0) ? worldScaleY : worldScaleX;
				wrapper.scale.y *= flipY;

				wrapper.x = bone.worldX + _matrix.tx;
				wrapper.y = bone.worldY + _matrix.ty;

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

	function getSprite(regionAttachment:RegionAttachment):FlxSprite
	{
		var wrapper = _regionWrappers[regionAttachment];
		if (wrapper != null && (wrapper is FlxSprite))
			return wrapper;

		var region:AtlasRegion = cast regionAttachment.rendererObject;
		var graph:FlxGraphic = cast region.page.rendererObject;

		var regionWidth:Float = region.rotate ? region.height : region.width;
		var regionHeight:Float = region.rotate ? region.width : region.height;

		var atlasFrames:FlxAtlasFrames = (graph.atlasFrames == null) ? new FlxAtlasFrames(graph) : graph.atlasFrames;

		var name:String = region.name;
		var offset:FlxPoint = FlxPoint.get(0, 0);
		var frameRect:FlxRect = new FlxRect(region.x, region.y, regionWidth, regionHeight);

		var sourceSize:FlxPoint = FlxPoint.get(frameRect.width, frameRect.height);
		var imageFrame = FlxImageFrame.fromFrame(atlasFrames.addAtlasFrame(frameRect, sourceSize, offset, name));

		var wrapper:FlxSprite = new FlxSprite();
		wrapper.frames = imageFrame;
		wrapper.antialiasing = antialiasing;

		wrapper.angle = -regionAttachment.rotation;
		wrapper.scale.x = regionAttachment.scaleX * (regionAttachment.width / region.width);
		wrapper.scale.y = regionAttachment.scaleY * (regionAttachment.height / region.height);

		// Position using attachment translation, shifted as if scale and rotation were at image center.
		var radians:Float = -regionAttachment.rotation * Math.PI / 180;
		var cos:Float = Math.cos(radians);
		var sin:Float = Math.sin(radians);
		var shiftX:Float = -regionAttachment.width / 2 * regionAttachment.scaleX;
		var shiftY:Float = -regionAttachment.height / 2 * regionAttachment.scaleY;

		if (region.rotate)
		{
			wrapper.angle += 90;
			shiftX += regionHeight * (regionAttachment.width / region.width);
		}

		wrapper.origin.x = regionAttachment.x + shiftX * cos - shiftY * sin;
		wrapper.origin.y = -regionAttachment.y + shiftX * sin + shiftY * cos;
		_regionWrappers[regionAttachment] = wrapper;
		return wrapper;
	}

	override function set_x(NewX:Float):Float
	{
		super.set_x(NewX);

		if (skeleton != null)
		{
			skeleton.x = NewX;

			if (collider != null)
			{
				if (skeleton.flipX)
					collider.x = skeleton.x - collider.offsetX - width;
				else
					collider.x = skeleton.x + collider.offsetX;
			}
		}

		return NewX;
	}

	override function set_y(NewY:Float):Float
	{
		super.set_y(NewY);

		if (skeleton != null)
		{
			skeleton.y = NewY;

			if (collider != null)
			{
				if (skeleton.flipY)
					collider.y = skeleton.y + collider.offsetY - height;
				else
					collider.y = skeleton.y - collider.offsetY;
			}
		}

		return NewY;
	}

	override function set_width(Width:Float):Float
	{
		super.set_width(Width);

		if (skeleton != null && collider != null)
			collider.width = Width;

		return Width;
	}

	override function set_height(Height:Float):Float
	{
		super.set_height(Height);

		if (skeleton != null && collider != null)
			collider.height = Height;

		return Height;
	}

	override function set_flipX(value:Bool):Bool
	{
		skeleton.flipX = value;
		set_x(x);
		return flipX = value;
	}

	override function set_flipY(value:Bool):Bool
	{
		skeleton.flipY = value;
		set_y(y);
		return flipY = value;
	}
}

class FlxSpineCollider extends FlxObject
{
	public var offsetX(default, set):Float = 0;
	public var offsetY(default, set):Float = 0;

	public var parent(default, null):FlxSpine;

	public function new(Parent:FlxSpine, X:Float = 0, Y:Float = 0, Width:Float = 0, Height:Float = 0, OffsetX:Float = 0, OffsetY:Float = 0)
	{
		super(X, Y, Width, Height);
		offsetX = OffsetX;
		offsetY = OffsetY;
		parent = Parent;
	}

	override public function destroy():Void
	{
		parent = null;
		super.destroy();
	}

	override function set_x(NewX:Float):Float
	{
		if (parent != null && x != NewX)
		{
			super.set_x(NewX);

			if (parent.skeleton.flipX)
				parent.x = NewX + offsetX + width;
			else
				parent.x = NewX - offsetX;
		}
		else
		{
			super.set_x(NewX);
		}

		return NewX;
	}

	override function set_y(NewY:Float):Float
	{
		if (parent != null && y != NewY)
		{
			super.set_y(NewY);

			if (parent.skeleton.flipY)
				parent.y = NewY - offsetY + height;
			else
				parent.y = NewY + offsetY;
		}
		else
		{
			super.set_y(NewY);
		}

		return NewY;
	}

	override function set_width(Width:Float):Float
	{
		if (parent != null && width != Width)
		{
			super.set_width(Width);
			parent.x = parent.x;
		}
		else
		{
			super.set_width(Width);
		}

		return Width;
	}

	override function set_height(Height:Float):Float
	{
		if (parent != null && height != Height)
		{
			super.set_height(Height);
			parent.y = parent.y;
		}
		else
		{
			super.set_height(Height);
		}

		return Height;
	}

	function set_offsetX(value:Float):Float
	{
		if (parent != null && offsetX != value)
		{
			offsetX = value;
			parent.x = parent.x;
		}
		else
		{
			offsetX = value;
		}

		return value;
	}

	function set_offsetY(value:Float):Float
	{
		if (parent != null && offsetY != value)
		{
			offsetY = value;
			parent.y = parent.y;
		}
		else
		{
			offsetY = value;
		}

		return value;
	}
}
