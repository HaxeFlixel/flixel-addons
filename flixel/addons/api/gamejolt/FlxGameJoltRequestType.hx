package flixel.addons.api.gamejolt;

/**
 * An enum of every single command currently available to request to GameJolt API.
 */
enum FlxGameJoltRequestType
{
	/**
	 * This allows you to make several requests in a single call.
	 * @param parallel		Whether if you want to execute all `requests` at once (true) or at the respective order (false).
	 * @param breakOnError Whether if you want this to return a general error message if one of the requests fails or not.
	 * @param requests		The list of the requests to call, you can set up to 50.
	 */
	BATCH(parallel:Bool, breakOnError:Bool, requests:Array<FlxGameJoltRequestType>);
	
	/**
	 * Retrieves data from the Data Store.
	 * @param key		The item whose data would you like to fetch.
	 * @param fromUser	Whether if you want to retrieve data from the registered user (true) or from the game itself (false).
	 */
	DATA_FETCH(key:String, fromUser:Bool);
	
	/**
	 * Retrieves all the keys registered in the Data Store.
	 * @param fromUser	Whether if you want to retrieve keys from the registered user (true) or from the game itself (false).
	 * @param pattern	Optional. The pattern to apply to the key names in the data store.
	 */
	DATA_GETKEYS(fromUser:Bool, ?pattern:String);
	
	/**
	 * Removes data from the Data Store.
	 * @param key		The item whose data would you like to remove.
	 * @param fromUser	Whether if you want to remove data from the registered user (true) or from the game itself (false).
	 */
	DATA_REMOVE(key:String, fromUser:Bool);
	
	/**
	 * Sets data to the Data Store.
	 * @param key		The item whose `data` is gonna be saved at.
	 * @param data		The data to save under the respective `key`.
	 * @param fromUser	Whether if you want to set data to the registered user (true) or to the game itself (false).
	 */
	DATA_SET(key:String, data:String, toUser:Bool);
	
	/**
	 * Updates data in the Data Store.
	 * @param key			The item whose data is gonna be updated at.
	 * @param operation		The update operation to perform.
	 * @param fromUser		Whether if you want to update data for the registered user (true) or for the game itself (false).
	 */
	DATA_UPDATE(key:String, operation:FlxGameJoltUpdateType, toUser:Bool);
	
	/**
	 * Retrieves a list of user IDs of every single friend of the registered user.
	 */
	FRIENDS;
	
	/**
	 * Retrieves the time and date of your game's server.
	 */
	TIME;
	
	/**
	 * Validates the existence of the registered user.
	 */
	USER_AUTH;
	
	/**
	 * Retrieves information from GameJolt users.
	 * @param userOrID The users to fetch information from. It can be a username of a single user, or a list of user IDs separated by commas.
	 */
	USER_FETCH(userOrID:String);
	
	/**
	 * Opens a session for the registered user.
	 */
	SESSION_OPEN;
	
	/**
	 * Pings the actual session of the registered user, if there's one active.
	 * @param active Whether to set the user's state as "active" (true) or "idle" (false).
	 */
	SESSION_PING(active:Bool);
	
	/**
	 * Checks if there's a session active for the registered user.
	 */
	SESSION_CHECK;
	
	/**
	 * Closes a session for the registered user, if there's one active.
	 */
	SESSION_CLOSE;
	
	/**
	 * Adds a score to your game.
	 * @param score			 The display text of the score.
	 * @param sort			 The score numerical value.
	 * @param extra_data	If some extra data is attached to this Score, you can put it here.
	 * @param table_id		 The score table ID to set this score to. If `null`, it'll be added to the primary score table of your game.
	 */
	SCORES_ADD(score:String, sort:Int, ?extra_data:String, ?table_id:Int);
	
	/**
	 * Retrieves the rank number of a particular score value.
	 * @param sort		The numerical value of the score.
	 * @param table_id	The score table ID to retrieve the rank from. If `null`, it'll be retrieved from the primary score table of your game.
	 */
	SCORES_GETRANK(sort:Int, ?table_id:Int);
	
	/**
	 * Retrieves the top scores of your game.
	 * @param fromUser		Whether if you want to retrieve only the score submitted by the registered user or not.
	 * @param table_id		The score table ID to retrieve the score from. If `null`, they'll be retrieved from the primary score table of your game.
	 * @param limit 		 How many scores to retrieve. Must be a value between 1-100, Default is 10.
	 * @param betterThan    If you want to retrieve only the scores that are HIGHER than some value, you can pass such value here.
	 * 						  NOTE: If you set a negative value, this will retrieve the scores that are LOWER than its value instead.
	 */
	SCORES_FETCH(fromUser:Bool, ?table_id:Int, ?limit:Int, ?betterThan:Int);
	
	/**
	 * Retrieves information about all the score tables in your game.
	 */
	SCORES_TABLES;
	
	/**
	 * Retrieves information about all the trophies in your game, and their status according to the registered user.
	 * @param achieved Whether if you want to get only achieved (true) or unachieved (false) trophies. Leave `null` to retrieve them all.
	 * @param trophy_id If you want to retrieve an specific trophy, you can pass its ID here. If not `null`, `achieved` will be ignored.
	 */
	TROPHIES_FETCH(?achieved:Bool, ?trophy_id:Int);
	
	/**
	 * Adds a trophy to the registered user.
	 * @param trophy_id The ID of the trophy to add.
	 */
	TROPHIES_ADD(trophy_id:Int);
	
	/**
	 * Removes a trophy to the registered user.
	 * @param trophy_id The ID of the trophy to remove.
	 */
	TROPHIES_REMOVE(trophy_id:Int);
}

/**
 * An enum class to clasify Data Store update functions.
 */
enum FlxGameJoltUpdateType
{
	Add(n:Int);
	Substract(n:Int);
	Multiply(n:Int);
	Divide(n:Int);
	Append(t:String);
	Prepend(t:String);
}
