package flixel.addons.api.gamejolt;

/**
 * An enum of every single command currently available to request to GameJolt API.
 */
enum FlxGameJoltRequest
{
	BATCH(parallel:Bool, breakOnError:Bool, requests:Array<FlxGameJoltRequest>);
	DATA_FETCH(key:String, fromUser:Bool);
	DATA_GETKEYS(fromUser:Bool, ?pattern:String);
	DATA_REMOVE(key:String, fromUser:Bool);
	DATA_SET(key:String, data:String, toUser:Bool);
	DATA_UPDATE(key:String, operation:FlxGameJoltUpdate, toUser:Bool);
	FRIENDS;
	TIME;
	USER_AUTH;
	USER_FETCH(userOrID:String);
	SESSION_OPEN;
	SESSION_PING(active:Bool);
	SESSION_CHECK;
	SESSION_CLOSE;
	SCORES_ADD(score:String, sort:Int, ?extra_data:String, ?table_id:Int);
	SCORES_GETRANK(sort:Int, ?table_id:Int);
	SCORES_FETCH(fromUser:Bool, ?table_id:Int, ?limit:Int, ?betterThan:Int);
	SCORES_TABLES;
	TROPHIES_FETCH(?achieved:Bool, ?trophy_id:Int);
	TROPHIES_ADD(trophy_id:Int);
	TROPHIES_REMOVE(trophy_id:Int);
}

/**
 * An enum class to clasify Data Store update functions.
 */
enum FlxGameJoltUpdate
{
	Add(n:Int);
	Substract(n:Int);
	Multiply(n:Int);
	Divide(n:Int);
	Append(t:String);
	Prepend(t:String);
}
