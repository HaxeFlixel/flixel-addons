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
using Reflect;
using StringTools;

typedef Param =
{
	key:String,
	value:String
}

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
	 * Creates a new section for URL creation. The `requestBatch()` function requires this for its entries to work correctly.
	 * @param command The command of the call section.
	 * @param action The action (if there's any) of the call section.
	 * @param params The parameters the call will take in count when requested.
	 * @param encode Whether to encode along with a signature at its end or not.
	 * @return The resulting section.
	 */
	public static function buildURLSection(command:String, action:String = "", params:Array<Param>, encode:Bool):String
	{
		var section:String = '/$command';
		if (action != "")
			section += '$action/';
		section += '?game_id=$gameID';

		for (f in params)
			section += '&${f.key}=${f.value}';
		if (encode)
		{
			section += '&signature=${encryptURL(section)}';
			return section.urlEncode();
		}
		return section;
	}

	private static function buildURL(command:String, action:String = "", params:Array<Param>):URLRequest
	{
		var url:String = 'https://api.gamejolt.com/api/game/v1_2';
		url += buildURLSection(command, action, params, false);
		url += '&signature=${encryptURL(url)}';
		return new URLRequest(url);
	}

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

	private static function initRequest<F>(request:URLRequest, field:FlxGameJoltResponse->F, ?onComplete:F->Void, ?onError:String->Void,
			?onProgress:Float->Float->Void):URLLoader
	{
		var loader:URLLoader = new URLLoader();
		loader.addEventListener(COMPLETE, function(_)
		{
			var data:FlxGameJoltResponse = parse(loader.data).response;
			if (data.message != null)
			{
				if (verbose)
					log.warn('${request.url}\nRequest Error: ${data.message}');
				if (onError != null)
					onError(data.message);
				return;
			}

			if (verbose)
				log.add(data);
			if (onComplete != null)
				onComplete(field(formatImages(data)));
		});
		loader.addEventListener(PROGRESS, function(p)
		{
			var l:Float = roundDecimal(p.bytesLoaded, 3);
			var t:Float = roundDecimal(p.bytesTotal, 3);

			if (verbose)
				log.add('${request.url}\nLoading... ${formatBytes(l)}/${formatBytes(t)} (${roundDecimal(l / t, 1)}%)');
			if (onProgress != null)
				onProgress(l, t);
		});
		loader.addEventListener(IO_ERROR, function(e)
		{
			var message:String = 'IO Error: ${e.text}';
			if (verbose)
				log.warn('${request.url}\n$message');
			if (onError != null)
				onError(message);
		});
		loader.addEventListener(SECURITY_ERROR, function(e)
		{
			var message:String = 'Security Error: ${e.text}';
			if (verbose)
				log.warn('${request.url}\n$message');
			if (onError != null)
				onError(message);
		});

		log.notice('Starting Request: ${request.url}');
		loader.load(request);
		return loader;
	}

	/**
	 * Retrieves date and time registered in your game's server.
	 * @see 	https://gamejolt.com/api/doc/game/time/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchServerTime(?onComplete:Date->Void, ?onError:String->Void, ?onProgress:Float->Float->Void):URLLoader
		return initRequest(buildURL("time", []), data -> Date.fromString('${data.year}-${data.month}-${data.day} ${data.hour}:${data.minute}:${data.second}'),
			onComplete, onError, onProgress);

	/**
	 * Sends multiple calls in a single request to the GameJolt API to process.
	 * @see 	https://gamejolt.com/api/doc/game/batch/
	 * @param	calls The list of calls to send to the batch. You can set up to 50 calls per batch. NOTE: Use `buildURLSection()` with its parameter `encode` set to `true` for the creation of every call you want to add here.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function requestBatch(calls:Array<String>, ?onComplete:Array<FlxGameJoltResponse>->Void, ?onError:String->Void,
			?onProgress:Float->Float->Void):URLLoader
	{
		return initRequest(buildURL("batch", calls.map(c -> {key: "responses[]", value: c.urlEncode()})), data -> data.responses, onComplete, onError,
			onProgress);
	}

	/**
	 * Retrieves the list of the registered user's friends' IDs.
	 * @see 	https://gamejolt.com/api/doc/game/friends/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchFriends(?onComplete:Array<Int>->Void, ?onError:String->Void, ?onProgress:Float->Float->Void):URLLoader
		return initRequest(buildURL("friends", [{key: "username", value: username}, {key: "user_token", value: usertoken}]),
			data -> data.friends.map(f -> f.friend_id), onComplete, onError, onProgress);

	/**
	 * Fetch users data by a given username.
	 * @see 	https://gamejolt.com/api/doc/game/users/fetch/
	 * @param	username	The username of the user whose data will be obtained from. If you leave this blank, `username` will be used instead.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchUserByUsername(username:String, onComplete:FlxGameJoltUser->Void, onError:String->Void,
			?onProgress:Float->Float->Void):URLLoader
		return initRequest(buildURL("users", "fetch", [{key: "username", value: username != "" ? username : FlxGameJolt.username}]), data -> data.users[0],
			onComplete, onError, onProgress);

	/**
	 * Fetch users data by a given user IDs list.
	 * @see 	https://gamejolt.com/api/doc/game/users/fetch/
	 * @param	userIDs	The user IDs list of the users whose data will be obtained from.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchUsersByIDs(userIDs:Array<Int>, onComplete:Array<FlxGameJoltUser>->Void, onError:String->Void,
			?onProgress:Float->Float->Void):URLLoader
		return initRequest(buildURL("users", "fetch", [{key: "user_id", value: userIDs.map(id -> '$id').join("%2C")}]), data -> data.users, onComplete,
			onError, onProgress);

	/**
	 * Verify user data set on `username` and `usertoken`.
	 * @see 	https://gamejolt.com/api/doc/game/users/auth/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function authUser(?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("users", "auth", [{key: "username", value: username}, {key: "user_token", value: usertoken}]), data -> {}, onComplete,
			onError);

	/**
	 * Begin a new session. Sessions that are not pinged using `pingSession()` at most every 120 seconds will be closed.
	 * @see 	https://gamejolt.com/api/doc/game/sessions/open/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function openSession(?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("sessions", "open", [{key: "username", value: username}, {key: "user_token", value: usertoken}]), data -> {}, onComplete,
			onError);

	/**
	 * Checks if the registered user has an active session in your game or not.
	 * @see 	https://gamejolt.com/api/doc/game/sessions/check/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function checkSession(?onComplete:Bool->Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("sessions", "check", [{key: "username", value: username}, {key: "user_token", value: usertoken}]), data -> data.success,
			onComplete, onError);

	/**
	 * Ping the current session. The API states that a session will be closed after 120 seconds without a ping, so it's recommended to call this frequently.
	 * Better to put it in a place where it runs all the time.
	 * @see 	https://gamejolt.com/api/doc/game/sessions/ping/
	 * @param	active		Leave true to set the session to active, or set to false to set the session to idle.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function pingSession(active:Bool = true, ?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("sessions", "ping", [
			{key: "username", value: username},
			{key: "user_token", value: usertoken},
			{key: "active", value: active ? "active" : "idle"}
		]), data -> {}, onComplete, onError);

	/**
	 * Close the current session, if there's one active.
	 * @see 	https://gamejolt.com/api/doc/game/sessions/close/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function closeSession(?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("sessions", "close", [{key: "username", value: username}, {key: "user_token", value: usertoken}]), data -> {}, onComplete,
			onError);

	/**
	 * Retrieve the list of trophies of your game, and their achievement status according to the registered user.
	 * @see 	https://gamejolt.com/api/doc/game/trophies/fetch/
	 * @param	achieved	Whether if you want to retrieve only the achieved trophies (true) or the unachieved ones (false). Leave `null` to retrieve every trophy.
	 * @param	trophy_id	If you want to set an specific trophy to retrieve, you can set it here. If set, `achieved` will be not taken in count.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchTrophies(?achieved:Bool, ?trophy_id:Int, ?onComplete:Array<FlxGameJoltTrophy>->Void, ?onError:String->Void,
			?onProgress:Float->Float->Void):URLLoader
	{
		var params:Array<Param> = [{key: "username", value: username}, {key: "user_token", value: usertoken}];
		if (achieved != null)
			params.push({key: "achieved", value: '$achieved'});
		if (trophy_id != null)
			params.push({key: "trophy_id", value: '$trophy_id'});
		return initRequest(buildURL("trophies", params), data -> data.trophies, onComplete, onError, onProgress);
	}

	/**
	 * Unlock a trophy for the registered user.
	 * @see 	https://gamejolt.com/api/doc/game/trophies/add-achieved/
	 * @param	trophy_id	The unique ID number for this trophy. Can be seen at https://gamejolt.com/dashboard/developer/games/achievements/GAME_ID/ in the right-hand column.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function addTrophy(trophy_id:Int, ?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("trophies", "add-achieved", [
			{key: "username", value: username},
			{key: "user_token", value: usertoken},
			{key: "trophy_id", value: '$trophy_id'}
		]), data -> {}, onComplete, onError);

	/**
	 * Locks a trophy for the registered user. Useful for trophy testing and such.
	 * @see 	https://gamejolt.com/api/doc/game/trophies/remove-achieved/
	 * @param	trophy_id	The unique ID number for this trophy. Can be seen at https://gamejolt.com/dashboard/developer/games/achievements/GAME_ID/ in the right-hand column.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function removeTrophy(trophy_id:Int, ?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("trophies", "remove-achieved", [
			{key: "username", value: username},
			{key: "user_token", value: usertoken},
			{key: "trophy_id", value: '$trophy_id'}
		]), data -> {}, onComplete, onError);

	/**
	 * Retrieve the high scores from a certain score table in your game.
	 * @see		https://gamejolt.com/api/doc/game/scores/fetch/
	 * @param 	table_id	The ID of the table you want to pull data from. Leave blank to fetch from the primary score table.
	 * @param	guest		The name of the "guest" whose scores are gonna be retrieved. If you set an empty string, it will include `username` and `usertoken` instead. Leave `null` to retrieve every score.
	 * @param	limit		The maximum number of scores to retrieve. Must be a value between 1-100 according to the API documentation. Default value is 10.
	 * @param 	betterThan Makes this to retrieve only the scores that are HIGHER than its value, if you set a negative value, this will retrieve the scores that are LOWER than its value instead.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchScores(?table_id:Int, ?guest:String, ?limit:Int, ?betterThan:Int, ?onComplete:Array<FlxGameJoltScore>->Void,
			?onError:String->Void, ?onProgress:Float->Float->Void):URLLoader
	{
		var params:Array<Param> = [];

		if (guest == "")
		{
			if (usertoken != "")
			{
				params.push({key: "username", value: username});
				params.push({key: "user_token", value: usertoken});
			}
			else
				params.push({key: "guest", value: username});
		}
		else if (guest != null)
			params.push({key: "guest", value: guest});

		if (limit != null)
			params.push({key: "limit", value: '$limit'});
		if (table_id != null)
			params.push({key: "table_id", value: '$table_id'});
		if (betterThan != null && betterThan != 0)
			params.push({key: betterThan > 0 ? "better_than" : "worse_than", value: '$betterThan'});

		return initRequest(buildURL("scores", params), data -> data.scores, onComplete, onError, onProgress);
	}

	/**
	 * Set a new high score, either globally or for this particular user.
	 * @see		https://gamejolt.com/api/doc/game/scores/add/
	 * @param	score		A string representation of the score, such as "234 Jumps".
	 * @param	sort		A numerical representation of the score, such as 234. Used for sorting of data.
	 * @param 	table_id	The ID of the table you'd like to send data to. If `null`, score will be sent to the primary high score table.
	 * @param	guest		The name of the "guest" whose score is gonna be set for. If you set an empty string, it will include `username` and `usertoken` instead..
	 * @param	extra_data	Optional extra data associated with the score, which will NOT be visible on the site but can be retrieved by the API.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function addScore(score:String, sort:Float, guest:String = "", ?table_id:Int, ?extra_data:String, ?onComplete:(Void) -> Void,
			?onError:String->Void):URLLoader
	{
		var params:Array<Param> = [{key: "score", value: score}, {key: "sort", value: '$sort'}];

		if (guest == "")
		{
			if (usertoken != "")
			{
				params.push({key: "username", value: username});
				params.push({key: "user_token", value: usertoken});
			}
			else
				params.push({key: "guest", value: username});
		}
		else
			params.push({key: "guest", value: guest});

		if (table_id != null)
			params.push({key: "table_id", value: '$table_id'});
		if (extra_data != null)
			params.push({key: "extra_data", value: '$extra_data'});

		return initRequest(buildURL("scores", "add", params), data -> {}, onComplete, onError);
	}

	/**
	 * Retrieve the rank of the score passed in.
	 * @see 	https://gamejolt.com/api/doc/game/scores/get-rank/
	 * @param	sort		A numerical representation of the score whose rank is gonna be retrieved from.
	 * @param 	table_id	The ID of the table you'd like to retrieve the rank from. If `null`, score will be retrieved from the primary high score table.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function getScoreRank(sort:Int, ?table_id:Int, ?onComplete:Int->Void, ?onError:String->Void, ?onProgress:Float->Float->Void):URLLoader
	{
		var params:Array<Param> = [{key: "sort", value: '$sort'}];
		if (table_id != null)
			params.push({key: "table_id", value: '$table_id'});
		return initRequest(buildURL("scores", "get-rank", params), data -> data.rank, onComplete, onError, onProgress);
	}

	/**
	 * Retrieve a list of high score tables for this game.
	 * @see 	https://gamejolt.com/api/doc/game/scores/tables/
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function getScoreTables(?onComplete:Array<FlxGameJoltScoreTable>->Void, ?onError:String->Void):URLLoader
		return initRequest(buildURL("scores", "tables", []), data -> data.tables, onComplete, onError);

	/**
	 * Get data from the remote data store.
	 * @see 	https://gamejolt.com/api/doc/game/data-store/fetch/
	 * @param	Key			The key for the data to retrieve.
	 * @param	User		Whether or not to get the data associated with this user.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function fetchData(Key:String, User:Bool, ?onComplete:String->Void, ?onError:String->Void, ?onProgress:Float->Float->Void):URLLoader
	{
		var params:Array<Param> = [{key: "key", value: Key}];
		if (User)
		{
			params.push({key: "username", value: username});
			params.push({key: "user_token", value: usertoken});
		}
		return initRequest(buildURL("data-store", "", params), data -> data.data, onComplete, onError, onProgress);
	}

	/**
	 * Set data in the remote data store.
	 * @see 	https://gamejolt.com/api/doc/game/data-store/set/
	 * @param	Key			The key for this data.
	 * @param	Value		The key value.
	 * @param	User		Whether or not to associate this with this user.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function setData(Key:String, Value:String, User:Bool, ?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
	{
		var params:Array<Param> = [{key: "key", value: Key}, {key: "value", value: Value.urlEncode()}];
		if (User)
		{
			params.push({key: "username", value: username});
			params.push({key: "user_token", value: usertoken});
		}
		return initRequest(buildURL("data-store", "set", params), data -> {}, onComplete, onError);
	}

	/**
	 * Update data which is in the data store.
	 * @see		https://gamejolt.com/api/doc/game/data-store/update/
	 * @param	Key			The key of the data you'd like to manipulate.
	 * @param	Operation	The type of operation. Acceptable values: "add", "subtract", "multiply", "divide", "append", "prepend". The former four are only valid on numerical values, the latter two only on strings.
	 * @param	Value		The value that you'd like to work with on the data store.
	 * @param	User		Whether or not to work with the data associated with this user.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function updateData(Key:String, Operation:String, Value:String, User:Bool, ?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
	{
		var params:Array<Param> = [
			{key: "key", value: Key},
			{key: "operation", value: Operation},
			{key: "value", value: Value.urlEncode()}
		];
		if (User)
		{
			params.push({key: "username", value: username});
			params.push({key: "user_token", value: usertoken});
		}
		return initRequest(buildURL("data-store", "update", params), data -> {}, onComplete, onError);
	}

	/**
	 * Remove data from the remote data store.
	 * @see 	https://gamejolt.com/api/doc/game/data-store/remove/
	 * @param	Key			The key for the data to remove.
	 * @param	User		Whether or not to remove the data associated with this user.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @return The request instance.
	 */
	public static function removeData(Key:String, User:Bool, ?onComplete:(Void) -> Void, ?onError:String->Void):URLLoader
	{
		var params:Array<Param> = [{key: "key", value: Key}];
		if (User)
		{
			params.push({key: "username", value: username});
			params.push({key: "user_token", value: usertoken});
		}
		return initRequest(buildURL("data-store", "remove", params), data -> {}, onComplete, onError);
	}

	/**
	 * Get all keys in the data store.
	 * @see 	https://gamejolt.com/api/doc/game/data-store/get-keys/
	 * @param	User		Whether or not to get the keys associated with this user.
	 * @param	onComplete	Callback that will contain the requested data, if the request ends successfully.
	 * @param	onError	Callback that will contain the error information of the request, if the request fails.
	 * @param	onProgress	Callback that will be called while the request is loading results.
	 * @return The request instance.
	 */
	public static function getAllKeys(User:Bool, ?onComplete:Array<String>->Void, ?onError:String->Void, ?onProgress:Float->Float->Void):URLLoader
	{
		var params:Array<Param> = [];
		if (User)
		{
			params.push({key: "username", value: username});
			params.push({key: "user_token", value: usertoken});
		}
		return initRequest(buildURL("data-store", "get-keys", params), data -> data.keys.map(k -> k.key), onComplete, onError, onProgress);
	}

	private static function encryptURL(url:String):String
		return usingMd5 ? Md5.encode(url + gameKey) : Sha1.encode(url + gameKey);
}
