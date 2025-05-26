//
import Modifier;
import Xml;
var enabled = Options.gameplayShaders;

public var modcharts = true;
public var opponentPlay = PlayState.opponentMode;
public var showOnlyStrums = false;

public var camOther:FlxCamera;

var shaders:Array<CustomShader> = [];
var shaderList:Array<String> = [];
function getShaderIndex(n:String) {
	if (shaderList.indexOf(n) != -1)
		return shaderList.indexOf(n);
		
	shaderList.push(n);
	return shaderList.length-1;
}

var iTimeShaderData = [];
/*
{
	shader: null,
	iTime: 0,
	hasSpeed: false
}
*/

//basically the playstate version uses this instead of storing multiple strings with every single event/shader/modifier
//using a string array that will be indexed from
//should hopefully give better performance!
//(makes the code much harder to understand though)
var valueNameList:Array<String> = [];
function getValueIndex(n:String) {
	if (valueNameList.indexOf(n) != -1)
		return valueNameList.indexOf(n);
		
	valueNameList.push(n);
	return valueNameList.length-1;
}
var shaderNamesList:Array<String> = [];
var shaderPropertiesList:Array<String> = [];
var shaderIndexList:Array<Int> = [];

var defaultValueList:Array<Float> = [];
var currentValueList:Array<Float> = [];
var eventIndexList:Array<Int> = [];

var events:Array<Dynamic> = [];

function getEventTypeID(name) {
	switch(name) {
		case "setShaderProperty": return 0;
		case "tweenShaderProperty": return 1;
		case "setModifierValue": return 2;
		case "tweenModifierValue": return 3;
		case "addCameraZoom": return 4;
		case "addHUDZoom": return 5;
	}
	return -1;
}

var noteModifiers:Array<Int> = [];

function destroy() {
	for (s in shaders) s = null;
	shaders.splice(0, shaders.length);

	shaderList.splice(0, shaderList.length);
	valueNameList.splice(0, valueNameList.length);
	shaderNamesList.splice(0, shaderNamesList.length);
	shaderPropertiesList.splice(0, shaderPropertiesList.length);
	shaderIndexList.splice(0, shaderIndexList.length);
	defaultValueList.splice(0, defaultValueList.length);
	currentValueList.splice(0, currentValueList.length);
	eventIndexList.splice(0, eventIndexList.length);
	noteModifiers.splice(0, noteModifiers.length);
	for (e in events) e = null;
	events.splice(0, events.length);
}

function loadEvents() {
	var xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart.xml");
	if (Assets.exists(Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml"))) {
		xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml");
	}
	if (!Assets.exists(xmlPath)) return;

	var xml = Xml.parse(Assets.getText(xmlPath)).firstElement();

	if (xml.get("noteModchart") == "true") {
		importScript("data/scripts/modchartManager.hx");
	}

	for (list in xml.elementsNamed("Init")) {
		for (event in list.elementsNamed("Event")) {
			switch(event.get("type")) {
				case "initShader":
					var path = event.get("shader");

					var s = new CustomShader(path);
					shaders[getShaderIndex(event.get("name"))] = s;
					
					var iTimeData = null;
					if (Assets.exists("shaders/"+path+".txt")) {
						var data = Assets.getText("shaders/"+path+".txt");
						for (vari in data.split("\n")) {
							var d = vari.split(" ");

							var n = event.get("name") + "." + d[0];
							if (!valueNameList.contains(n)) {
								defaultValueList[getValueIndex(n)] = Std.parseFloat(d[1]);
							}
							s.hset(d[0], Std.parseFloat(d[1]));

							if (d[0] == 'iTime') {
								if (iTimeData == null) iTimeData = {shader: s, iTime: 0, hasSpeed: false};
								s.iTime = 0;
							}
							if (d[0] == "speed") {
								if (iTimeData == null) iTimeData = {shader: s, iTime: 0, hasSpeed: false};
								s.speed = 1;
								iTimeData.hasSpeed = true;
							}
						}
					}
					if (iTimeData != null) {
						iTimeShaderData.push(iTimeData);
					}
				case "setCameraShader":

					var s = shaders[getShaderIndex(event.get("name"))];
					var camName = event.get("camera");

					var cam:FlxCamera = camGame;
					if (camName == "hud" || camName == "camHUD") {
						cam = camHUD;
					} else if (camName == "other") {
						cam = camOther;
					}

					if (s != null) {
						cam.addShader(s);
					}
						

				case "setShaderProperty":
					var n = event.get("name") + "." + event.get("property");
					defaultValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));
				case "initModifier":

					var n = event.get("name");
					var v = Std.parseFloat(event.get("value"));

					defaultValueList[getValueIndex(n)] = v;

					if (!noteModifiers.contains(getValueIndex(n))) noteModifiers.push(getValueIndex(n));

					createModifier(n, 
						v, 
						event.get("code"), 
						event.exists("strumLineID") ? Std.parseInt(event.get("strumLineID")) : -1, 
						event.exists("strumID") ? Std.parseInt(event.get("strumID")) : -1, 
						event.exists("defaultValue") ? Std.parseFloat(event.get("defaultValue")) : 0.0, 
						event.exists("autoDisable") ? event.get("autoDisable") == "true" : false
					);
			}
		}
	}
	for (i in 0...defaultValueList.length) {
		currentValueList[i] = defaultValueList[i];
	}
	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			switch(event.get("type")) {
				case "setShaderProperty":
					var n = event.get("name") + "." + event.get("property");
					if (!valueNameList.contains(n)) {
						currentValueList[getValueIndex(n)] = defaultValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));
					}
					events.push({
						"type": getEventTypeID(event.get("type")),
						"step": Std.parseFloat(event.get("step")),
						"name": getValueIndex(n),
						"value": Std.parseFloat(event.get("value"))
					});

					currentValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));

				case "tweenShaderProperty":
					var n = event.get("name") + "." + event.get("property");
					if (!valueNameList.contains(n)) {
						currentValueList[getValueIndex(n)] = defaultValueList[getValueIndex(n)] = 0;
					}
					
					events.push({
						"type": getEventTypeID(event.get("type")),
						"step": Std.parseFloat(event.get("step")),
						"name": getValueIndex(n),
						"value": Std.parseFloat(event.get("value")),
						"time": Std.parseFloat(event.get("time")),
						"ease": getEase(event.get("ease")),
						"startValue": event.exists("startValue") ? Std.parseFloat(event.get("startValue")) : currentValueList[getValueIndex(n)]
					});

					//DI = Downscroll Inverse
					if (event.exists("DI_startValue")) {
						if (downscroll && event.get("DI_startValue") == "true") {
							events[events.length-1].startValue *= -1;
						}
					}
					if (event.exists("DI_value")) {
						if (downscroll && event.get("DI_value") == "true") {
							events[events.length-1].value *= -1;
						}
					}

					if (events[events.length-1].step <= -1) {
						events[events.length-1].step = 0;
					}

					currentValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));

				case "addCameraZoom" | "addHUDZoom":
					events.push({
						"type": getEventTypeID(event.get("type")),
						"step": Std.parseFloat(event.get("step")),
						"value": Std.parseFloat(event.get("value")),
						"triggered": false
					});
				case "setModifierValue":
					var n = event.get("name");
					if (!valueNameList.contains(n)) {
						currentValueList[getValueIndex(n)] = defaultValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));
					}
					events.push({
						"type": getEventTypeID(event.get("type")),
						"step": Std.parseFloat(event.get("step")),
						"name": getValueIndex(n),
						"value": Std.parseFloat(event.get("value"))
					});

					currentValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));

				case "tweenModifierValue":
					var n = event.get("name");
					if (!valueNameList.contains(n)) {
						currentValueList[getValueIndex(n)] = defaultValueList[getValueIndex(n)] = 0;
					}

					events.push({
						"type": getEventTypeID(event.get("type")),
						"step": Std.parseFloat(event.get("step")),
						"name": getValueIndex(n),
						"value": Std.parseFloat(event.get("value")),
						"time": Std.parseFloat(event.get("time")),
						"ease": getEase(event.get("ease")),
						"startValue": event.exists("startValue") ? Std.parseFloat(event.get("startValue")) : currentValueList[getValueIndex(n)]
					});

					if (events[events.length-1].step <= -1) {
						events[events.length-1].step = 0;
					}

					currentValueList[getValueIndex(n)] = Std.parseFloat(event.get("value"));
			}
		}
	}
	initModchart();
	resetValuesToDefault();
	//refreshEventTimings();

	events.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});

}
function resetValuesToDefault() {
	for (i in 0...defaultValueList.length) {
		var data = valueNameList[i].split(".");

		var s = shaders[getShaderIndex(data[0])];
		if (s != null) {
			shaderNamesList[i] = data[0];
			shaderPropertiesList[i] = data[1];
			shaderIndexList[i] = getShaderIndex(data[0]);
			s.hset(data[1], defaultValueList[i]);
		} else {
			shaderNamesList[i] = null;
			shaderPropertiesList[i] = null;
			shaderIndexList[i] = -1;
		}
		
		currentValueList[i] = defaultValueList[i];
	}
}

function postUpdate(elapsed) {

	if (!modcharts) return;
	
	var i = 0;
	for (e in events) {
		if (curStepFloat < e.step) {
			break;
		}

		if (curStepFloat >= e.step) {
			switch(e.type) {
				case 0 | 2:
					
					setValue(e.name, e.value);
					events.remove(e);
				case 1 | 3:
					if (curStepFloat < e.step + e.time) {
								
						var l = 0 + (curStepFloat - e.step) * ((1 - 0) / ((e.step + e.time) - e.step));
						var newValue = FlxMath.lerp(e.startValue, e.value, e.ease(l));
		
						setValue(e.name, newValue);
					} else {
						setValue(e.name, e.value);
						events.remove(e);
					}
				case 4:
					camGame.zoom += e.value;
					events.remove(e);
				case 5:
					camHUD.zoom += e.value;
					events.remove(e);
			}
		}
		
	}

	for (data in iTimeShaderData) {
		if (data.hasSpeed) {
			data.iTime += (FlxG.elapsed * data.shader.speed);
			data.shader.iTime = data.iTime;
		} else {
			data.shader.iTime = Conductor.songPosition*0.001;
		}
	}
}

function setValue(i, value) {

	if (noteModifiers.indexOf(i) != -1) {

		var obj = valueNameList[i];
		var mod = null;
		for (m in modifiers) {
			if (m[MOD_NAME] == obj) {
				mod = m;
				break;
			}
		}


		if (mod != null) {
			mod[MOD_VALUE] = value;
		}

	} else {
		var s = shaders[shaderIndexList[i]];
		if (s != null) {
			s.hset(shaderPropertiesList[i], value);
		}
	}
}

function hideHUD() {
	showOnlyStrums = true;
	for (obj in [scoreTxt, missesTxt, accuracyTxt, healthBarBG, healthBar, iconP1, iconP2]) {
		obj.visible = !showOnlyStrums;
	}
}
function showHUD() {
	showOnlyStrums = false;
	for (obj in [scoreTxt, missesTxt, accuracyTxt, healthBarBG, healthBar, iconP1, iconP2]) {
		obj.visible = !showOnlyStrums;
	}
}

function create() {
	camOther = new FlxCamera();
	camOther.bgColor = 0;
	FlxG.cameras.add(camOther, false);
}
function postCreate() {
	if (!modcharts) return;

	//importScript("data/scripts/modchartManager.hx");
	//modTable.addModifier(new Modifier("drunkTest", 1, -1, -1, [new SubModifier("speed", 3)], "drunk"));
	//modTable.addModifier(new Modifier("z", 100, 1, -1, [], "z"));
	//modTable.addModifier(new Modifier("rot", 3, -1, -1, [new SubModifier("x", 45), new SubModifier("y", 0), new SubModifier("z", 45)], "strumLineRotate"));

	//initModchart();

	//loadEvents();
}

function getEase(ease:String)
{
	switch (ease.toLowerCase())
	{
		case 'backin': 
			return FlxEase.backIn;
		case 'backinout': 
			return FlxEase.backInOut;
		case 'backout': 
			return FlxEase.backOut;
		case 'bouncein': 
			return FlxEase.bounceIn;
		case 'bounceinout': 
			return FlxEase.bounceInOut;
		case 'bounceout': 
			return FlxEase.bounceOut;
		case 'circin': 
			return FlxEase.circIn;
		case 'circinout':
			return FlxEase.circInOut;
		case 'circout': 
			return FlxEase.circOut;
		case 'cubein': 
			return FlxEase.cubeIn;
		case 'cubeinout': 
			return FlxEase.cubeInOut;
		case 'cubeout': 
			return FlxEase.cubeOut;
		case 'elasticin': 
			return FlxEase.elasticIn;
		case 'elasticinout': 
			return FlxEase.elasticInOut;
		case 'elasticout': 
			return FlxEase.elasticOut;
		case 'expoin': 
			return FlxEase.expoIn;
		case 'expoinout': 
			return FlxEase.expoInOut;
		case 'expoout': 
			return FlxEase.expoOut;
		case 'quadin': 
			return FlxEase.quadIn;
		case 'quadinout': 
			return FlxEase.quadInOut;
		case 'quadout': 
			return FlxEase.quadOut;
		case 'quartin': 
			return FlxEase.quartIn;
		case 'quartinout': 
			return FlxEase.quartInOut;
		case 'quartout': 
			return FlxEase.quartOut;
		case 'quintin': 
			return FlxEase.quintIn;
		case 'quintinout': 
			return FlxEase.quintInOut;
		case 'quintout': 
			return FlxEase.quintOut;
		case 'sinein': 
			return FlxEase.sineIn;
		case 'sineinout': 
			return FlxEase.sineInOut;
		case 'sineout': 
			return FlxEase.sineOut;
		case 'smoothstepin': 
			return FlxEase.smoothStepIn;
		case 'smoothstepinout': 
			return FlxEase.smoothStepInOut;
		case 'smoothstepout': 
			return FlxEase.smoothStepInOut;
		case 'smootherstepin': 
			return FlxEase.smootherStepIn;
		case 'smootherstepinout': 
			return FlxEase.smootherStepInOut;
		case 'smootherstepout': 
			return FlxEase.smootherStepOut;
		default: 
			return FlxEase.linear;
	}
}