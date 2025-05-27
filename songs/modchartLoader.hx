//
import Modifier;
import Xml;

var enabled = Options.gameplayShaders;

public var modcharts = true;
public var opponentPlay = PlayState.opponentMode;
public var showOnlyStrums = false;

public var camOther:FlxCamera;

/*
{
	name: "",
	property: "",
	type: 0,
	value: 0,
	object: null
}
*/
public var modchartItems = [];

function getModchartItemID(name) {
	switch(name) {
		case "modifier": return 0;
		case "shader": return 1;
	}
	return -1;
}

function createModchartItem(n, p, t, v, o) {
	var item = {
		name: n,
		property: p,
		type: t,
		value: v,
		object: o
	};
	modchartItems.push(item);
	return item;
}

/*
{
	//base
	step: 0,
	type: 0,
	itemIndex: 0,
	value: 0

	//tweens
	"time": 0,
	"ease": null,
	startValue: 0,
}
*/
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

var noteModchart = false;

function destroy() {
	for (e in modchartItems) e = null;
	modchartItems.splice(0, modchartItems.length);
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

	for (list in xml.elementsNamed("Init")) {
		for (node in list.elementsNamed("Shader")) {

			var path = "modcharts/" + node.get("shader");
			var s = new CustomShader(path);
			
			for (prop in node.elementsNamed("Property")) {
				createModchartItem(node.get("name"), prop.get("name"), 1, Std.parseFloat(prop.get("value")), s);
			}

			if (node.exists("camGame") && node.get("camGame") == "true") {
				camGame.addShader(s);
			}
			if (node.exists("camHUD") && node.get("camHUD") == "true") {
				camHUD.addShader(s);
			}
			if (node.exists("camOther") && node.get("camOther") == "true") {
				camOther.addShader(s);
			}
		}

		for (node in list.elementsNamed("Modifier")) {
			if (!noteModchart) {
				noteModchart = true;
				importScript("data/scripts/modchartManager.hx");
				useNotePaths = true;
			}

			var subMods = [];
			for (sub in node.elementsNamed("SubMod")) {
				subMods.push(new SubModifier(sub.get("name"), Std.parseFloat(sub.get("value"))));
			}
			var modifier = new Modifier(
				node.get("name"), 
				Std.parseFloat(node.get("value")),
				Std.parseInt(node.get("strumLineID")),
				Std.parseInt(node.get("strumID")),
				subMods,
				node.get("modifier")
			);
			modTable.addModifier(modifier);

			createModchartItem(node.get("name"), "value", 0, Std.parseFloat(node.get("value")), modifier);
			for (submod in subMods) {
				createModchartItem(node.get("name"), submod.name, 0, submod.value, submod);
			}
		}
	}
	
	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			switch(event.get("type")) {
				case "setShaderProperty" | "setModifierValue":
					var name = event.get("name");
					var prop = event.get("property");

					for (i => item in modchartItems) {
						if (item.name == name && item.property == prop) {
							events.push({
								"type": getEventTypeID(event.get("type")),
								"step": Std.parseFloat(event.get("step")),
								"itemIndex": i,
								"value": Std.parseFloat(event.get("value")),
							});
							break;
						}
					}

				case "tweenShaderProperty" | "tweenModifierValue":
					var name = event.get("name");
					var prop = event.get("property");


					for (i => item in modchartItems) {
						if (item.name == name && item.property == prop) {
							events.push({
								"type": getEventTypeID(event.get("type")),
								"step": Std.parseFloat(event.get("step")),
								"itemIndex": i,
								"value": Std.parseFloat(event.get("value")) * (downscroll && event.exists("DI_value") && event.get("DI_value") == "true" ? -1 : 1),
								"time": Std.parseFloat(event.get("time")),
								"ease": getEase(event.get("ease")),
								"startValue": Std.parseFloat(event.get("startValue")) * (downscroll && event.exists("DI_startValue") && event.get("DI_startValue") == "true" ? -1 : 1)
							});
							break;
						}
					}

				case "addCameraZoom" | "addHUDZoom":
					events.push({
						"type": getEventTypeID(event.get("type")),
						"step": Std.parseFloat(event.get("step")),
						"value": Std.parseFloat(event.get("value"))
					});
			}
		}
	}
	initModchart();

	events.sort(function(a, b) {
		if(a.step < b.step) return -1;
		else if(a.step > b.step) return 1;
		else return 0;
	});
}

function postUpdate(elapsed) {

	if (!modcharts) return;
	
	for (e in events) {
		if (curStepFloat < e.step) {
			break;
		}

		if (curStepFloat >= e.step) {
			switch(e.type) {
				case 0:
					modchartItems[e.itemIndex].hset(modchartItems[e.itemIndex].property, e.value);
					events.remove(e);
				case 2:
					modchartItems[e.itemIndex].object.value = e.value;
					events.remove(e);
				case 1:
					if (curStepFloat < e.step + e.time) {
						var l = (curStepFloat - e.step) * ((1) / ((e.step + e.time) - e.step));		
						modchartItems[e.itemIndex].hset(modchartItems[e.itemIndex].property, FlxMath.lerp(e.startValue, e.value, e.ease(l)));
					} else {
						trace(e);
						modchartItems[e.itemIndex].hset(modchartItems[e.itemIndex].property, e.value);
						events.remove(e);
					}
				case 3:
					if (curStepFloat < e.step + e.time) {
						var l = (curStepFloat - e.step) * ((1) / ((e.step + e.time) - e.step));		
						modchartItems[e.itemIndex].object.value = FlxMath.lerp(e.startValue, e.value, e.ease(l));
					} else {
						modchartItems[e.itemIndex].object.value = e.value;
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

	/*for (data in iTimeShaderData) {
		if (data.hasSpeed) {
			data.iTime += (FlxG.elapsed * data.shader.speed);
			data.shader.iTime = data.iTime;
		} else {
			data.shader.iTime = Conductor.songPosition*0.001;
		}
	}*/
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

	loadEvents();
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