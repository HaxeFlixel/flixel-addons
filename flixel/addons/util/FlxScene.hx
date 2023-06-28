package flixel.addons.util;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tile.FlxTilemap;
import flixel.ui.FlxButton;
import flixel.util.FlxAxes;
import flixel.util.FlxColor;
import haxe.xml.Parser;
import openfl.Assets;

using haxe.EnumTools;

import haxe.xml.Access;

/**
 * Loads a scene from XML file. Scenes contain layers of entities (custom FlxSprite),
 * backgrounds, tilemaps, constants, UI and more.
 *
 * Any questions tweet me @AndreiRegiani
 */
class FlxScene
{
	/**
	 * <scene width=""> attribute.
	 */
	public var width(default, null):Int;

	/**
	 * <scene height=""> attribute.
	 */
	public var height(default, null):Int;

	/**
	 * <scene name=""> attribute.
	 */
	public var name(default, null):String;

	/**
	 * <scene description=""> attribute.
	 */
	public var description(default, null):String;

	/**
	 * <scene version=""> attribute.
	 */
	public var version(default, null):String;

	/**
	 * Base directory for all assets loaded inside FlxScene.
	 */
	public var assetsDirectory:String = "assets/";

	/**
	 * Tilemap reference.
	 */
	public var tilemap:FlxTilemap;

	/**
	 * Contains all constants declared in <constants>.
	 */
	var _constants:Map<String, Dynamic>;

	/**
	 * Contains all objects with an "id" attribute.
	 */
	var _objects:Map<String, Dynamic>;

	/**
	 * Internal XML.
	 */
	var _xml:Xml;

	/**
	 * Internal xml.Access.
	 */
	var _fastXml:Access;

	/**
	 * Optionally set the scene file already.
	 *
	 * @param	file 	Location of XML.
	 */
	public function new(?file:String)
	{
		if (file != null)
			set(file);
	}

	/**
	 * Set the current scene, loads from XML file.
	 *
	 * @param	file 	Location of XML.
	 */
	public function set(file:String):Void
	{
		_constants = new Map<String, Dynamic>();
		_objects = new Map<String, Dynamic>();

		var data:String = Assets.getText(file);

		_xml = Parser.parse(data);
		_fastXml = new Access(_xml.firstElement());

		// <scene> attributes

		if (_fastXml.has.width)
			width = Std.parseInt(_fastXml.att.width);

		if (_fastXml.has.height)
			height = Std.parseInt(_fastXml.att.height);

		if (_fastXml.has.name)
			name = _fastXml.att.name;

		if (_fastXml.has.description)
			description = _fastXml.att.description;

		if (_fastXml.has.version)
			version = _fastXml.att.version;

		if (_fastXml.has.bgColor)
			FlxG.cameras.bgColor = FlxColor.fromString(_fastXml.att.bgColor);

		if (_fastXml.hasNode.constants)
			loadConstants();
	}

	/**
	 * Instantiate objects to state.
	 *
	 * @param container 	Add objects to this FlxTypedGroup (layer).
	 * @param layerId 		Add objects only from this layer.
	 */
	public function spawn(?container:FlxTypedGroup<Dynamic>, ?layerId:String):Void
	{
		var layerNodes = _fastXml.nodes.layer;

		// every <layer>
		for (layer in layerNodes)
		{
			// only specific <layer id="layerId"> OR every if none is specified
			if (layerId == null || layer.att.id == layerId)
			{
				// every <entity>, <sprite>, <text> inside specific layer (layerId)
				for (element in layer.elements)
				{
					switch (element.name)
					{
						case "sprite":
							var instance = new FlxSprite();
							applySpriteProperties(instance, element);

							addInstance(instance, container, element);

						case "entity":
							var instance = Type.createInstance(Type.resolveClass(element.att.type), []);
							applySpriteProperties(instance, element);

							addInstance(instance, container, element);

						case "text":
							var instance = new FlxText();
							applySpriteProperties(instance, element);
							applyTextProperties(instance, element);

							addInstance(instance, container, element);

						case "button":
							var instance = new FlxButton();
							applySpriteProperties(instance, element);
							applyTextProperties(instance.label, element);

							addInstance(instance, container, element);
					}
				}

				if (layerId != null)
					break;
			}
		}
	}

	/**
	 * Add backgrounds to state.
	 *
	 * @param container 	Add backgrounds to this FlxTypedGroup (layer).
	 */
	public function loadBackgrounds(?container:FlxTypedGroup<Dynamic>):Void
	{
		var backgroundsNode = _fastXml.node.resolve("backgrounds");

		// <backgrounds>
		for (element in backgroundsNode.elements)
		{
			// <backdrop>, <sprite>
			switch (element.name)
			{
				case "backdrop":
					var att = element.att;
					var graphics:String = assetsDirectory + att.graphics;
					var repeatAxes = FlxAxes.fromBools(parseBool(att.repeatX), parseBool(att.repeatY));

					var backdrop = new FlxBackdrop(graphics, repeatAxes);
					backdrop.x = Std.parseInt(att.x);
					backdrop.y = Std.parseInt(att.y);
					backdrop.scrollFactor.x = Std.parseFloat(att.scrollFactorX);
					backdrop.scrollFactor.y = Std.parseFloat(att.scrollFactorY);

					addInstance(backdrop, container, element);

				case "sprite":
					var sprite = new FlxSprite();
					applySpriteProperties(sprite, element);

					addInstance(sprite, container, element);
			}
		}
	}

	/**
	 * Add tilemap to state.
	 *
	 * @param container 	Add tilemap to this FlxTypedGroup (layer).
	 */
	public function loadTilemap(?container:FlxTypedGroup<Dynamic>):Void
	{
		var terrainNode = _fastXml.node.resolve("terrain");

		// <terrain>
		for (element in terrainNode.elements)
		{
			// <tilemap>, <tile>
			switch (element.name)
			{
				case "tilemap":
					var data:String = element.innerData;
					var graphics:String = element.att.graphics;
					var width:Int = Std.parseInt(element.att.tileWidth);
					var height:Int = Std.parseInt(element.att.tileHeight);

					tilemap = new FlxTilemap();
					tilemap.loadMapFromCSV(data, graphics, width, height);

					addInstance(tilemap, container, element);

				case "tile":
					var id = Std.parseInt(element.att.id);
					var collision = Std.parseInt(element.att.collision);

					tilemap.setTileProperties(id, collision);
			}
		}
	}

	/**
	 * Add everything (backgrounds, tilemap and all objects) to the state.
	 */
	public function loadEverything():Void
	{
		loadBackgrounds();
		loadTilemap();
		spawn();
	}

	/**
	 * Make constants accesible through function FlxScene.constants("id").
	 */
	function loadConstants():Void
	{
		// <constants>
		var constantsNode = _fastXml.node.resolve("constants");

		// <const>
		for (element in constantsNode.elements)
		{
			// Check if it's <const>, and has all attributes: id, type and value.
			if (element.name == "const" && element.has.id && element.has.type && element.has.value)
			{
				switch (element.att.type)
				{
					case "Bool":
						var const:Bool = parseBool(element.att.value);
						_constants.arrayWrite(element.att.id, const);

					case "Int":
						var const:Int = Std.parseInt(element.att.value);
						_constants.arrayWrite(element.att.id, const);

					case "Float":
						var const:Float = Std.parseFloat(element.att.value);
						_constants.arrayWrite(element.att.id, const);

					case "String":
						var const:String = element.att.value;
						_constants.arrayWrite(element.att.id, const);
				}
			}
		}
	}

	/**
	 * Add an instance into correct destination (a specific group or FlxG.state).
	 * If has attribute "id" then make it accesible through function: object("id").
	 *
	 * @param 	instance 	Instance to be added to container.
	 * @param 	container 	FlxTypedGroup.
	 * @param 	element 	XML attributes.
	 */
	function addInstance(instance:Dynamic, container:FlxTypedGroup<Dynamic>, element:Access):Void
	{
		if (container == null)
			FlxG.state.add(instance);
		else
			container.add(instance);

		if (element.has.id)
			_objects.arrayWrite(element.att.id, instance);
	}

	/**
	 * Apply all FlxSprite properties to a given instance.
	 *
	 * @param 	instance 	Instance to set properties.
	 * @param 	element 	XML attributes.
	 */
	function applySpriteProperties(instance:FlxSprite, element:Access):Void
	{
		// From FlxSprite

		if (element.has.graphic)
			instance.loadGraphic(assetsDirectory + element.att.graphic);

		if (element.has.alpha)
			instance.alpha = Std.parseFloat(element.att.alpha);

		if (element.has.color)
			instance.color = FlxColor.fromString(element.att.color);

		if (element.has.flipX)
			instance.flipX = parseBool(element.att.flipX);

		if (element.has.flipY)
			instance.flipY = parseBool(element.att.flipY);

		if (element.has.originX)
			instance.origin.x = Std.parseFloat(element.att.originX);

		if (element.has.originY)
			instance.origin.y = Std.parseFloat(element.att.originY);

		if (element.has.offsetX)
			instance.offset.x = Std.parseFloat(element.att.offsetX);

		if (element.has.offsetY)
			instance.offset.y = Std.parseFloat(element.att.offsetY);

		if (element.has.scaleX)
			instance.scale.x = Std.parseFloat(element.att.scaleX);

		if (element.has.scaleY)
			instance.scale.y = Std.parseFloat(element.att.scaleY);

		// From FlxObject

		if (element.has.x)
			instance.x = Std.parseFloat(element.att.x);

		if (element.has.y)
			instance.y = Std.parseFloat(element.att.y);

		if (element.has.width)
			instance.width = Std.parseFloat(element.att.width);

		if (element.has.height)
			instance.height = Std.parseFloat(element.att.height);

		if (element.has.angle)
			instance.angle = Std.parseFloat(element.att.angle);

		if (element.has.immovable)
			instance.immovable = parseBool(element.att.immovable);

		if (element.has.solid)
			instance.solid = parseBool(element.att.solid);

		if (element.has.scrollFactorX)
			instance.scrollFactor.x = Std.parseFloat(element.att.scrollFactorX);

		if (element.has.scrollFactorY)
			instance.scrollFactor.y = Std.parseFloat(element.att.scrollFactorY);

		// Alignment properties

		if (element.has.alignBottom)
			instance.y = FlxG.height - instance.height - Std.parseInt(element.att.alignBottom);

		if (element.has.alignRight)
			instance.x = FlxG.width - instance.width - Std.parseInt(element.att.alignRight);

		if (element.has.alignVertical)
			instance.y = (FlxG.height / 2) - (instance.height / 2) + Std.parseInt(element.att.alignVertical);

		if (element.has.alignHorizontal)
			instance.x = (FlxG.width / 2) - (instance.width / 2) + Std.parseInt(element.att.alignHorizontal);

		// From FlxBasic

		if (element.has.visible)
			instance.visible = parseBool(element.att.visible);
	}

	/**
	 * Apply all FlxText properties to a given instance.
	 *
	 * @param 	instance 	Instance to set properties.
	 * @param 	element 	XML attributes.
	 */
	function applyTextProperties(instance:FlxText, element:Access):Void
	{
		if (instance == null || element == null)
			return;

		if (element.has.text)
			instance.text = element.att.text;

		if (element.has.size)
			instance.size = Std.parseInt(element.att.size);

		if (element.has.fieldWidth)
			instance.fieldWidth = Std.parseInt(element.att.fieldWidth);

		if (element.has.font)
			instance.font = assetsDirectory + element.att.font;

		if (element.has.alignment)
			instance.alignment = element.att.alignment;

		if (element.has.borderStyle)
			instance.borderStyle = FlxTextBorderStyle.createByName(element.att.borderStyle.toUpperCase());

		if (element.has.borderColor)
			instance.borderColor = FlxColor.fromString(element.att.borderColor);

		if (element.has.borderSize)
			instance.borderSize = Std.parseInt(element.att.borderSize);

		if (element.has.wordWrap)
			instance.wordWrap = parseBool(element.att.wordWrap);
	}

	/**
	 * Gets a specific constant by ID.
	 *
	 * @param 	id 	Constant name.
	 * @return 	Bool, Int, Float or String associated with the ID.
	 */
	public function const(id:String):Dynamic
	{
		if (_constants.exists(id))
		{
			return _constants.get(id);
		}

		return null;
	}

	/**
	 * Gets a specific object by ID.
	 *
	 * @param 	id 	Constant name.
	 * @return	The object associated with the ID.
	 */
	public function object(id:String):Dynamic
	{
		if (_objects.exists(id))
		{
			return _objects.get(id);
		}

		return null;
	}

	/**
	 * Helper function to parse Booleans from String to Bool
	 *
	 * @param value 	String value
	 */
	function parseBool(value:String):Bool
	{
		if (value == "false" || Std.parseInt(value) == 0)
			return false;
		else
			return true;
	}
}
