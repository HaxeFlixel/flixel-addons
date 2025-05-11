package flixel.addons.api.gamejolt;

import flixel.FlxG.log;
import flixel.math.FlxMath.roundDecimal;
import flixel.util.FlxStringUtil.formatBytes;
import haxe.Json.parse;
import haxe.crypto.Md5;
import haxe.crypto.Sha1;
import openfl.events.Event.COMPLETE;
import openfl.events.IOErrorEvent.IO_ERROR;
import openfl.events.ProgressEvent.PROGRESS;
import openfl.events.SecurityErrorEvent.SECURITY_ERROR;
import openfl.net.URLLoader;
import openfl.net.URLRequest;

using Lambda;
using StringTools;

/**
 * This allows access to the GameJolt API. Based on the GameJolt Workspace in Postman made by Pablo Gálvez (GamerPablito).
 * @see 	https://postman.com/gamerpablito/gamejolt-api-workspace
 * @see 	https://gamejolt.com/game-api
 * @author 	Pablo Gálvez (GamerPablito)
 */
class FlxGameJolt
{
	/**
	 * Whether or not to log obtained messages returned from the requests.
	 * Useful if you're not getting the right data back.
	 */
	public static var verbose:Bool = false;

	/**
	 * The user's GameJolt user name.
	 */
	public static var username:String = "";

	/**
	 * The user's GameJolt user token. Can only be red by the class itself for security.
	 */
	public static var usertoken(null, default):String = "";

	/**
	 * Internal storage for this game's ID.
	 */
	public static var gameID:Int = 0;

	/**
	 * Internal storage for this game's private key. Can only be red by the class itself for security.
	 * Do NOT store your private key as a string literal in your game code!
	 * This can be found at https://gamejolt.com/dashboard/games/GAME_ID/api/settings where GAME_ID is your unique game ID number.
	 * Each game has a unique private key, you cannot use one key for all of your games.
	 */
	public static var gameKey(null, default):String = "";

	/**
	 * If `true`, requests will use `Md5` encryptation for calls.
	 * Otherwise, they'll use `Sha1` encryptation instead.
	 */
	public static var usingMd5:Bool = true;

	/**
	 * Converts a `FlxGameJoltRequest` instance into a piece of stringified URL.
	 * @param	request	The `FlxGameJoltRequest` that will be converted to String.
	 * @param	segment	Whether if the request will be parse like an URL segment or not (internal use only, keep it `false`).
	 * @return	The new URL piece.
	 */
	private static function buildURL(request:FlxGameJoltRequest, segment:Bool = false):String
	{
		var command:String = "";
		var action:String = "";
		var params:Array<{name:String, value:String}> = [];

		switch (request)
		{
			case BATCH(parallel, breakOnError, requests):
				command = "batch";
				params.push({name: "parallel", value: '$parallel'});
				params.push({name: "break_on_error", value: '$breakOnError'});
				for (req in requests)
					params.push({name: "requests[]", value: buildURL(req, true)});
			case DATA_FETCH(key, fromUser):
				command = "data-store";
				params.push({name: "key", value: key.urlEncode()});
				if (fromUser)
				{
					params.push({name: "username", value: FlxGameJolt.username});
					params.push({name: "user_token", value: FlxGameJolt.usertoken});
				}
			case DATA_GETKEYS(fromUser, pattern):
				command = "data-store";
				action = "get-keys";
				if (pattern != null && pattern != "")
					params.push({name: "pattern", value: pattern.urlEncode()});
				if (fromUser)
				{
					params.push({name: "username", value: FlxGameJolt.username});
					params.push({name: "user_token", value: FlxGameJolt.usertoken});
				}
			case DATA_REMOVE(key, fromUser):
				command = "data-store";
				action = "remove";
				params.push({name: "key", value: key.urlEncode()});
				if (fromUser)
				{
					params.push({name: "username", value: FlxGameJolt.username});
					params.push({name: "user_token", value: FlxGameJolt.usertoken});
				}
			case DATA_SET(key, data, toUser):
				command = "data-store";
				action = "set";
				params.push({name: "key", value: key.urlEncode()});
				params.push({name: "data", value: data.urlEncode()});
				if (toUser)
				{
					params.push({name: "username", value: FlxGameJolt.username});
					params.push({name: "user_token", value: FlxGameJolt.usertoken});
				}
			case DATA_UPDATE(key, operation, toUser):
				command = "data-store";
				action = "update";
				params.push({name: "key", value: key.urlEncode()});
				if (toUser)
				{
					params.push({name: "username", value: FlxGameJolt.username});
					params.push({name: "user_token", value: FlxGameJolt.usertoken});
				}
				switch (operation)
				{
					case Add(n):
						params.push({name: 'operation', value: 'add'});
						params.push({name: 'value', value: '$n'});
					case Substract(n):
						params.push({name: 'operation', value: 'substract'});
						params.push({name: 'value', value: '$n'});
					case Multiply(n):
						params.push({name: 'operation', value: 'multiply'});
						params.push({name: 'value', value: '$n'});
					case Divide(n):
						params.push({name: 'operation', value: 'divide'});
						params.push({name: 'value', value: '$n'});
					case Append(t):
						params.push({name: 'operation', value: 'append'});
						params.push({name: 'value', value: t.urlEncode()});
					case Prepend(t):
						params.push({name: 'operation', value: 'prepend'});
						params.push({name: 'value', value: t.urlEncode()});
				}
			case FRIENDS:
				command = "friends";
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case TIME:
				command = "time";
			case USER_AUTH:
				command = "users";
				action = "auth";
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case USER_FETCH(userOrID):
				command = "users";
				var letters:Array<String> = "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ_-".split("");
				if (letters.exists(l -> userOrID.contains(l.toUpperCase()) || userOrID.contains(l.toLowerCase())))
					params.push({name: "username", value: userOrID});
				else
					params.push({name: "user_id", value: userOrID.replace(",", "%2C")});
			case SESSION_OPEN:
				command = "sessions";
				action = "open";
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case SESSION_PING(active):
				command = "sessions";
				action = "ping";
				params.push({name: "status", value: active ? "active" : "idle"});
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case SESSION_CHECK:
				command = "sessions";
				action = "check";
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case SESSION_CLOSE:
				command = "sessions";
				action = "close";
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case SCORES_ADD(score, sort, extra_data, table_id):
				command = "scores";
				action = "add";
				params.push({name: "score", value: score});
				params.push({name: "sort", value: '$sort'});
				if (extra_data != null && extra_data != "")
					params.push({name: "extra_data", value: extra_data.urlEncode()});
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
				if (FlxGameJolt.usertoken != "")
				{
					params.push({name: "username", value: FlxGameJolt.username});
					params.push({name: "user_token", value: FlxGameJolt.usertoken});
				}
				else
					params.push({name: "guest", value: FlxGameJolt.username});
			case SCORES_GETRANK(sort, table_id):
				command = "scores";
				action = "get-rank";
				params.push({name: "sort", value: '$sort'});
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
			case SCORES_FETCH(fromUser, table_id, limit, betterThan):
				command = "scores";
				if (table_id != null)
					params.push({name: "table_id", value: '$table_id'});
				if (limit != null)
					params.push({name: "limit", value: '$limit'});
				if (betterThan != null)
					params.push({name: betterThan < 0 ? "worse_than" : "better_than", value: '${Math.abs(betterThan)}'});
				if (fromUser)
				{
					if (FlxGameJolt.usertoken != "")
					{
						params.push({name: "username", value: FlxGameJolt.username});
						params.push({name: "user_token", value: FlxGameJolt.usertoken});
					}
					else
						params.push({name: "guest", value: FlxGameJolt.username});
				}
			case SCORES_TABLES:
				command = "scores";
				action = "tables";
			case TROPHIES_FETCH(achieved, trophy_id):
				command = "trophies";
				if (achieved != null)
					params.push({name: "achieved", value: '$achieved'});
				if (trophy_id != null)
					params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case TROPHIES_ADD(trophy_id):
				command = "trophies";
				action = "add";
				params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
			case TROPHIES_REMOVE(trophy_id):
				command = "trophies";
				action = "remove";
				params.push({name: "trophy_id", value: '$trophy_id'});
				params.push({name: "username", value: FlxGameJolt.username});
				params.push({name: "user_token", value: FlxGameJolt.usertoken});
		}

		var urlSection:String = '/$command${action != "" ? '/$action' : ""}?game_id=${FlxGameJolt.gameID}${[for (p in params) '&${p.name}=${p.value}'].join("")}';
		if (segment)
			return sign(urlSection).urlEncode();
		return sign('https://api.gamejolt.com/api/game/v1_2$urlSection');
	}

	/**
	 * Corrects the image links in order to make them look with better resolution when fetched,
	 * @param	res	The response with the image link to improve
	 * @return	The passed-in response with the improved image links.
	 */
	private static function formatImages(res:FlxGameJoltResponse):FlxGameJoltResponse
	{
		if (res.users != null)
			res.users.iter(u -> u.avatar_url = '${u.avatar_url.substring(0, 32)}1000${u.avatar_url.substr(34)}'.replace(".jpg", ".png")
				.replace(".webp", ".png"));
		if (res.trophies != null)
			res.trophies.iter(function(t)
			{
				var newUrl:String = "";
				if (t.image_url.startsWith('https://m.'))
					newUrl = '${t.image_url.substring(0, 37)}1000${t.image_url.substr(40)}'.replace(".jpg", ".png").replace(".webp", ".png");
				else
				{
					newUrl = "https://s.gjcdn.net/assets/";
					newUrl += switch (t.image_url.substring(24).replace(".jpg", "").replace(".webp", ""))
					{
						case "trophy-bronze-1": "9c2c91d0";
						case "trophy-silver-1": "b46e352e";
						case "trophy-gold-1": "363ce2dc";
						case "trophy-platinum-1": "92e5330d";
						default: "";
					};
					newUrl += ".png";
				}
				t.image_url = newUrl;
			});
		if (res.responses != null)
			res.responses.iter(res2 -> res2 = formatImages(res2));
		return res;
	}

	/**
	 * Sends a request to the GameJolt API.
	 * The response may vary according to the request you pass in.
	 * Check out the GameJolt API docs for more info.
	 * @param	request		The request to send.
	 * @param	onResponse	Optional callback for the response obtained from the request processing.
	 * @param	onProgress	Optional callback to be executed while a response is obtained.
	 * @return	The `URLLoader` object that represents the request.
	 */
	public static function sendRequest(request:FlxGameJoltRequest, ?onResponse:FlxGameJoltResponse->Void, ?onProgress:Float->Float->Void):URLLoader
	{
		var url:String = buildURL(request);
		var loader:URLLoader = new URLLoader();

		loader.addEventListener(COMPLETE, function(_)
		{
			var data:FlxGameJoltResponse = formatImages(cast parse(loader.data).response);
			if (data.message != null)
			{
				data.message = 'Request Error: ${data.message}';
				if (verbose)
					log.warn('$url\n${data.message}');
				if (onResponse != null)
					onResponse(data);
				return;
			}

			if (data.responses != null)
				for (i in 0...data.responses.length)
					if (data.responses[i].message != null && verbose)
						log.warn('$url\nError at Subrequest #$i -> ${data.responses[i].message}');

			if (verbose)
			{
				log.notice('Request Finished: $url');
				log.add(data);
			}
			if (onResponse != null)
				onResponse(data);
		});
		loader.addEventListener(PROGRESS, function(p)
		{
			var l:Float = roundDecimal(p.bytesLoaded, 3);
			var t:Float = roundDecimal(p.bytesTotal, 3);

			if (verbose)
				log.add('$url\nLoading... ${formatBytes(l)}/${formatBytes(t)} (${roundDecimal(l / t, 1)}%)');
			if (onProgress != null)
				onProgress(l, t);
		});
		loader.addEventListener(IO_ERROR, function(e)
		{
			var message:String = 'IO Error: ${e.text}';
			if (verbose)
				log.warn('$url\n$message');
			if (onResponse != null)
				onResponse({success: false, message: message});
		});
		loader.addEventListener(SECURITY_ERROR, function(e)
		{
			var message:String = 'Security Error: ${e.text}';
			if (verbose)
				log.warn('$url\n$message');
			if (onResponse != null)
				onResponse({success: false, message: message});
		});

		log.notice('Starting Request: $url');
		loader.load(new URLRequest(url));
		return loader;
	}

	/**
	 * Adds the respective signature to an URL piece, according to `usingMd5`.
	 * @param	url	The URL piece to generate and add the signature to.
	 * @return	The URL with the signature included.
	 */
	private static function sign(url:String):String
	{
		var urlToEncode:String = url + gameKey;
		return '$url&signature=${usingMd5 ? Md5.encode(urlToEncode) : Sha1.encode(urlToEncode)}';
	}
}
