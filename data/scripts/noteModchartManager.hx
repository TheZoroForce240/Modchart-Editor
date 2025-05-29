//

import Camera3D;
import ModifierTable;

public var modchartCamera = new Camera3D();
public var modTable:ModifierTable = new ModifierTable();

var modchartInitialized = false;

public var modchartManagerKeyCount:Int = 4;
public var useNotePaths = false;
public var notePathGroup = [];

function postUpdate(elapsed)
{
	if (!modchartInitialized)
		return;

	//modchartCamera.position.x = Math.sin(Conductor.songPosition * 0.001);
	//modchartCamera.position.z = Math.cos(Conductor.songPosition * 0.001);

	//updateModifers();
	modchartCamera.updateViewMatrix();
	//shader updates
	for(p in 0...strumLines.length)
	{
		if (PlayState.instance != null) {
			for (strum in strumLines.members[p]) {
				updateStrum(strum, p);
			}
		} else {
			for (strum in strumLines[p]) {
				updateStrum(strum, p);
			}
		}

		if (PlayState.instance != null)
		{
			strumLines.members[p].notes.limit = 2500 / scrollSpeed;
			strumLines.members[p].notes.forEach(function(n)
			{
				if (n.shader == null) {
					n.shader = modTable.getShader(p, n.strumID);
				}
				n.forceIsOnScreen = true;
				//n.shader.viewMatrix = modchartCamera.viewMatrix;
				//n.shader.songPosition = Conductor.songPosition;
				//n.shader.curBeat = Conductor.curBeatFloat;
				//n.shader.downscroll = downscroll;
				n.shader.isSustainNote = n.isSustainNote;
				//if (n.isSustainNote)
	
				if (n.frame != null)
					n.shader.frameUV = [n.frame.uv.x,n.frame.uv.y,n.frame.uv.width,n.frame.uv.height];
	
				var curPos = Conductor.songPosition - n.strumTime;
				var nextCurPos = curPos;
	
				//curpos for next sustain to match
				if (n.isSustainNote && n.nextNote != null && n.nextNote.isSustainNote) 
					nextCurPos = Conductor.songPosition - n.nextNote.strumTime;
	
				//sustain ends
				if (n.isSustainNote && n.nextSustain == null) 
					nextCurPos = Conductor.songPosition - (n.strumTime + (Conductor.stepCrochet*0.5));
	
				//clip to strum
				if (n.isSustainNote && n.wasGoodHit && curPos >= 0) 
					curPos = 0;
	
	
				//calculate screen position for rotation and scaling inside shader
				var point = FlxPoint.weak();
				n.getScreenPosition(point, camHUD);
				n.shader.screenX = (n.origin.x + point.x - n.offset.x) + n.__strum.x;
				if (downscroll)
					n.shader.screenY = (n.origin.y + point.y - n.offset.y) - n.__strum.y;
				else
					n.shader.screenY = (n.origin.y + point.y - n.offset.y) + n.__strum.y;
				point.put();
	
				
				n.shader.strumID = n.strumID;
				n.shader.strumLineID = p;
				n.shader.data.noteCurPos.value = [curPos, curPos, nextCurPos, nextCurPos];
				n.shader.scrollSpeed = strumLines.members[p].members[n.strumID].getScrollSpeed(n);
			});
		}
	}
}
function updateStrum(strum, p) {
	if (strum.shader == null) {
		strum.shader = modTable.getShader(p, strum.ID);
	}
	
	strum.shader.viewMatrix = modchartCamera.viewMatrix;
	strum.shader.perspectiveMatrix = modchartCamera.perspectiveMatrix;
	strum.shader.songPosition = Conductor.songPosition;
	strum.shader.curBeat = Conductor.curBeatFloat;

	strum.shader.strumID = strum.ID;
	strum.shader.strumLineID = p;
	strum.shader.data.noteCurPos.value = [0.0, 0.0, 0.0, 0.0];
	strum.shader.scrollSpeed = 0.0;

	if (strum.frame != null)
		strum.shader.frameUV = [strum.frame.uv.x,strum.frame.uv.y,strum.frame.uv.width,strum.frame.uv.height];


	//calculate screen position for rotation and scaling inside shader
	var point = FlxPoint.weak();
	strum.getScreenPosition(point, camHUD);
	strum.shader.screenX = strum.origin.x + point.x - strum.offset.x;
	strum.shader.screenY = strum.origin.y + point.y - strum.offset.y;
	point.put();

	strum.shader.downscroll = downscroll;
	strum.shader.isSustainNote = false;

	modTable.applyValuesToShader(strum.shader, p, strum.ID);
}

function onDeleteNote(e) {
	modTable.putShader(e.note.shader, e.note.strumLine.ID, e.note.strumID);
}

public function initModchart()
{
	modchartInitialized = true;
	modTable.init();

	var segmentsToMake = Math.ceil((3500 / PlayState.SONG.scrollSpeed) / (Conductor.stepCrochet));

	for(p in 0...strumLines.length) {
		if (PlayState.instance != null) {
			strumLines.members[p].onNoteDelete.add(onDeleteNote);
		}

		if (useNotePaths) {
			notePathGroup.push([]);
			if (PlayState.instance != null) {
				shitarray = strumLines.members[p].members;
			} else {
				shitarray = strumLines[p];
			}
			for (i => strum in shitarray) {
				notePathGroup[p].push([]);

				var curTime = 0;
				for (l in 0...segmentsToMake) {
					var lineSpr = new FlxSprite(strum.x + 50, 56 + strum.y + (curTime * 0.45 * PlayState.SONG.scrollSpeed));
					lineSpr.makeGraphic(1,1);
					lineSpr.setGraphicSize(10, Math.ceil(Conductor.stepCrochet * 0.45 * PlayState.SONG.scrollSpeed));
					lineSpr.updateHitbox();
					lineSpr.cameras = [camHUD];
					lineSpr.forceIsOnScreen = true;
					notePathGroup[p][i].push(lineSpr);
					insert(0, lineSpr);
					curTime += Conductor.stepCrochet;
				}
			}
		}
	}

	if (useNotePaths) updateNotePaths();
}

public function updateNotePaths() {
	for(p in 0...strumLines.length) {
		var shitarray = [];
		if (PlayState.instance != null) {
			shitarray = strumLines.members[p].members;
		} else {
			shitarray = strumLines[p];
		}
		for (i => strum in shitarray) {

			var curTime = 0;
			for (lineSpr in notePathGroup[p][i]) {
				var n = lineSpr;
				n.shader = modTable.getShader(p, i);
				n.shader.isSustainNote = true;

				if (n.frame != null) n.shader.frameUV = [n.frame.uv.x,n.frame.uv.y,n.frame.uv.width,n.frame.uv.height];
				var point = FlxPoint.weak();
				n.getScreenPosition(point, camHUD);
				n.shader.screenX = (n.origin.x + point.x - n.offset.x);
				if (downscroll)
					n.shader.screenY = (n.origin.y + point.y - n.offset.y);// - strum.y;
				else
					n.shader.screenY = (n.origin.y + point.y - n.offset.y);// + strum.y;
				point.put();

				var time = -curTime;
				var nextTime = -(curTime + Conductor.stepCrochet);

				n.shader.strumID = i;
				n.shader.strumLineID = p;
				if (downscroll) {
					n.shader.data.noteCurPos.value = [nextTime, nextTime, time, time];
				} else {
					n.shader.data.noteCurPos.value = [time, time, nextTime, nextTime];
				}
				
				n.shader.scrollSpeed = PlayState.SONG.scrollSpeed;

				curTime += Conductor.stepCrochet;
			}

		}
	}
}

//fixes for splashes
function onNoteHit(event)
{
	if (event.showSplash)
	{
		event.showSplash = false;
		
		//show splash func (but we need to keep the splash sprite for after)
		splashHandler.__grp = splashHandler.getSplashGroup(event.note.splash);
		var splash = splashHandler.__grp.showOnStrum(event.note.__strum);
		splash.shader = event.note.__strum.shader;
		splashHandler.add(splash);
		// max 8 rendered splashes
		while(splashHandler.members.length > 8)
			splashHandler.remove(splashHandler.members[0], true);
	}
}