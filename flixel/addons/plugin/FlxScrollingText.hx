/**
 * FlxScrollingText
 * -- Part of the Flixel Power Tools set
 * 
 * v1.0 First version released
 * 
 * @version 1.0 - May 5th 2011
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
 * @co-author Ungar Djordje / ArtBIT (HaXe port)
*/

package plugins;
import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.*;
import flixel.plugin.FlxPlugin;
import flixel.addons.text.FlxBitmapFont;

class FlxScrollingText extends FlxPlugin
{
    private static var members:Map<FlxSprite, Dynamic> = new Map<FlxSprite, Dynamic>();
    private static var zeroPoint:Point = new Point(0,0);

    /**
     * Adds an FlxBitmapFont to the Scrolling Text Manager and returns an FlxSprite which contains the text scroller in it.<br />
     * The FlxSprite will automatically update itself via this plugin, but can be treated as a normal FlxSprite in all other regards<br />
     * re: positioning, collision, rotation, etc.
     * 
     * @param	bitmapFont			A pre-prepared FlxBitmapFont object (see the Test Suite examples for details on how this works)
     * @param	region				A Rectangle that defines the size of the scrolling FlxSprite. The sprite will be placed at region.x/y and be region.width/height in size.
     * @param	pixels				The number of pixels to scroll per step. For a smooth (but slow) scroll use low values. Keep the value proportional to the font width, so if the font width is 16 use a value like 1, 2, 4 or 8.
     * @param	steps				How many steps should pass before the text is next scrolled? Default 0 means every step we scroll. Higher values slow things down.
     * @param	text				The default text for your scrolling message. Can be changed in real-time via the addText method.
     * @param	onlyScrollOnscreen	Only update the text scroller when this FlxSprite is visible on-screen? Default true.
     * @param	loopOnWrap			When the scroller reaches the end of the given "text" should it wrap to the start? Default true. If false it will clear the screen then set itself to not update.
     * 
     * @return	An FlxSprite of size region.width/height, positioned at region.x/y, that auto-updates its contents while this plugin runs
     */
    public static function add(bitmapFont:FlxBitmapFont, region:Rectangle, pixels:UInt = 1, steps:UInt = 0, text:String = "FLIXEL ROCKS!", onlyScrollOnscreen:Bool = true, loopOnWrap:Bool = true):FlxSprite
    {
        var data:Dynamic = {};
        
        //	Sanity checks
        if (pixels > bitmapFont.characterWidth)
        {
            pixels = bitmapFont.characterWidth;
        }
        
        if (pixels == 0)
        {
            pixels = 1;
        }
        
        if (text == "")
        {
            text = " ";
        }
        
        data.bitmapFont = cast(bitmapFont, FlxBitmapFont);
        data.bitmapChar = data.bitmapFont.getCharacterAsBitmapData(text.charAt(0));
        data.charWidth = bitmapFont.characterWidth;
        data.charHeight = bitmapFont.characterHeight;
        data.shiftRect = new Rectangle(pixels, 0, region.width - pixels, region.height);
        data.bufferRect = new Rectangle(0, 0, region.width, region.height);
        data.slice = new Rectangle(0, 0, pixels, data.charHeight);
        data.endPoint = new Point(region.width - pixels, 0);
        data.x = 0;
        
        data.sprite = new FlxSprite(Std.int(region.x), Std.int(region.y)).makeGraphic(Std.int(region.width), Std.int(region.height), 0x0, true);
        data.buffer = new BitmapData(Std.int(region.width), Std.int(region.height), true, 0x0);
        
        data.region = region;
        data.step = steps;
        data.maxStep = steps;
        data.pixels = pixels;
        data.clearCount = 0;
        data.clearDistance = region.width - pixels;
        
        data.text = text;
        data.currentChar = 0;
        data.maxChar = text.length;
        
        data.wrap = loopOnWrap;
        data.complete = false;
        data.scrolling = true;
        data.onScreenScroller = onlyScrollOnscreen;
        
        scroll(data);
        
        members.set(data.sprite, data);
        
        return data.sprite;
    }
    
    /**
     * Adds or replaces the text in the given Text Scroller.<br />
     * Can be called while the scroller is still active.
     * 
     * @param	source		The FlxSprite Text Scroller you wish to update (must have been added to FlxScrollingText via a call to add()
     * @param	text		The text to add or update to the Scroller
     * @param	overwrite	If true the given text will fully replace the previous scroller text. If false it will be appended to the end (default)
     */
    public static function addText(source:FlxSprite, text:String, overwrite:Bool = false):Void
    {
        if (overwrite)
        {
            members.get(source).text = text;
        }
        else
        {
            members.get(source).text = members.get(source).text.concat(text);
        }
            
        members.get(source).maxChar = members.get(source).text.length;
    }
    
    override public function draw():Void
    {
        for (obj in members)
        {
            if (obj != null && (obj.onScreenScroller == true && obj.sprite.onScreen()) && obj.scrolling == true && obj.sprite.exists)
            {
                scroll(obj);
            }
        }
    }
    
    private static function scroll(data:Dynamic):Void
    {
        //	Have we reached enough steps?
        
        if (data.maxStep > 0 && (data.step < data.maxStep))
        {
            data.step++;
            
            return;
        }
        else
        {
            //	It's time to render, so reset the step counter and lets go
            data.step = 0;
        }
        
        //	CLS
        data.buffer.fillRect(data.bufferRect, 0x0);
        
        //	Shift the current contents of the buffer along by "speed" pixels
        data.buffer.copyPixels(cast(data.sprite, FlxSprite).pixels, data.shiftRect, zeroPoint, null, null, true);
        
        //	Copy the side of the character
        if (data.complete == false)
        {
            data.buffer.copyPixels(data.bitmapChar, data.slice, data.endPoint, null, null, true);
            
            //	Update
            data.x += data.pixels;
            
            if (data.x >= data.charWidth)
            {
                //	Get the next character
                data.currentChar++;
                
                if (data.currentChar > data.maxChar)
                {
                    //	At the end of the text
                    if (data.wrap)
                    {
                        data.currentChar = 0;
                    }
                    else
                    {
                        data.complete = true;
                        data.clearCount = 0;
                    }
                }
                
                if (data.complete == false)
                {
                    data.bitmapChar = data.bitmapFont.getCharacterAsBitmapData(data.text.charAt(data.currentChar));
                    data.x = 0;
                }
            }
            
            if (data.complete == false)
            {
                data.slice.x = data.x;
            }
        }
        else
        {
            data.clearCount += data.pixels;
            
            //	It's all over now
            if (data.clearCount >= data.clearDistance)
            {
                //	No point updating something that has since left the screen
                data.scrolling = false;
            }
        }
        
        cast(data.sprite, FlxSprite).pixels = data.buffer.clone();
        data.sprite.dirty = true;
    }
    
    /**
     * Removes all FlxSprites<br />
     * This is called automatically if the plugin is destroyed, but should be called manually by you if you change States<br />
     * as all the FlxSprites will be destroyed by Flixel otherwise
     */
    public static function clear():Void
    {
        for (obj in members)
        {
            members.remove(obj.sprite);
        }
    }
    
    /**
     * Starts scrolling on the given FlxSprite. If no FlxSprite is given it starts scrolling on all FlxSprites currently added.<br />
     * Scrolling is enabled by default, but this can be used to re-start it if you have stopped it via stopScrolling.<br />
     * 
     * @param	source	The FlxSprite to start scrolling on. If left as null it will start scrolling on all sprites.
     */
    public static function startScrolling(source:FlxSprite = null):Void
    {
        if (source != null)
        {
            members.get(source).scrolling = true;
        }
        else
        {
            for (obj in members)
            {
                obj.scrolling = true;
            }
        }
    }
    
    /**
     * Stops scrolling on the given FlxSprite. If no FlxSprite is given it stops scrolling on all FlxSprites currently added.<br />
     * Scrolling is enabled by default, but this can be used to stop it.<br />
     * 
     * @param	source	The FlxSprite to stop scrolling on. If left as null it will stop scrolling on all sprites.
     */
    public static function stopScrolling(source:FlxSprite = null):Void
    {
        if (source != null)
        {
            members.get(source).scrolling = false;
        }
        else
        {
            for (obj in members)
            {
                obj.scrolling = false;
            }
        }
    }
    
    /**
     * Checks to see if the given FlxSprite is a Scrolling Text, and is actively scrolling or not<br />
     * Note: If the text is set to only scroll when on-screen, but if off-screen when this is called, it will still return true.
     * 
     * @param	source	The FlxSprite to check for scrolling on.
     * @return	Bool true is the FlxSprite was found and is scrolling, otherwise false
     */
    public static function isScrolling(source:FlxSprite):Bool
    {
        if (members.get(source))
        {
            return members.get(source).scrolling;
        }
        
        return false;
    }
    
    /**
     * Removes an FlxSprite from the Text Scroller. Note that it doesn't restore the sprite bitmapData.
     * 
     * @param	source	The FlxSprite to remove scrolling for.
     * @return	Bool	true if the FlxSprite was removed, otherwise false.
     */
    public static function remove(source:FlxSprite):Bool
    {
        if (members.exists(source))
        {
            members.remove(source);
            
            return true;
        }
        
        return false;
    }
    
    override public function destroy():Void
    {
        clear();
    }
    
}