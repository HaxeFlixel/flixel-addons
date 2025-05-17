package flixel.addons.api.gamejolt;

/**
 * A user fetched from the GameJolt API.
 */
typedef FlxGameJoltUser =
{
	/** The ID of the User. */
	var id:Int;
	
	/** The cathegory the User is cataloged like in GameJolt. */
	var type:String;
	
	/** The username of the User. (Also available for guests). */
	var username:String;
	
	/** The link of the avatar image of the User.*/
	var avatar_url:String;
	
	/** A short description about how long the User have been in GameJolt. */
	var signed_up:String;
	
	/** A long time stamp (in seconds) of when the User signed up. */
	var signed_up_timestamp:Int;
	
	/** A short description about the last time the User was found active in GameJolt. */
	var last_logged_in:String;
	
	/** A long time stamp (in seconds) of the last time the User logged in GameJolt. */
	var last_logged_in_timestamp:Int;
	
	/** The actual status of the User. */
	var status:String;
	
	/** The display name of the User. (Also available for guests). */
	var developer_name:String;
	
	/** The website of the User. */
	var developer_website:String;
	
	/** The description of the User. */
	var developer_description:String;
}
