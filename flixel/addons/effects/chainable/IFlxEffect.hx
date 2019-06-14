package flixel.addons.effects.chainable;

import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import openfl.display.BitmapData;

interface IFlxEffect extends IFlxDestroyable
{
	var active:Bool;
	var offset(default, null):FlxPoint;
	function update(elapsed:Float):Void;
	function apply(bitmapData:BitmapData):BitmapData;
}
