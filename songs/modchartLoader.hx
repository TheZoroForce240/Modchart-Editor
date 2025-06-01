//
import haxe.io.Path;
import Xml;

public var modcharts = true;
public var opponentPlay = PlayState.opponentMode;
public var camOther:FlxCamera;

public var eventScripts = ["" => null];
public var eventTypes = [];
public var itemScripts = ["" => null];
public var itemTypes = [];

var eventUpdateFuncs = [];

public var modchartItems = [];
public function createModchartItem(n, p, t, v, o) {
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

var events:Array<Dynamic> = [];

function destroy() {
	for (e in modchartItems) e = null;
	modchartItems.splice(0, modchartItems.length);
	for (e in events) e = null;
	events.splice(0, events.length);
}

function loadEvents() {

	eventScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartEvents/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			eventScripts.set(file, importScript("data/scripts/modchartEvents/" + file + ".hx"));
			eventTypes.push(file);
			eventUpdateFuncs.push(eventScripts.get(file).get("updateEventGame"));
		}
	}

	itemScripts.clear();
	for (path in Paths.getFolderContent('data/scripts/modchartTimelineItems/', true, null)) {
		if (Path.extension(path) == "hx") {
			var file = CoolUtil.getFilename(path);
			itemScripts.set(file, importScript("data/scripts/modchartTimelineItems/" + file + ".hx"));
			itemTypes.push(file);
		}
	}

	var xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart.xml");
	if (Assets.exists(Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml"))) {
		xmlPath = Paths.getPath("songs/"+PlayState.SONG.meta.name+"/modchart-" + PlayState.difficulty + ".xml");
	}
	if (!Assets.exists(xmlPath)) return;

	var xml = Xml.parse(Assets.getText(xmlPath)).firstElement();

	for (name => script in itemScripts) {
		script.call("setupDefaultsGame", []);
	}

	for (list in xml.elementsNamed("Init")) {
		for (name => script in itemScripts) {
			script.call("setupItemsFromXMLGame", [list]);
		}
	}
	
	for (list in xml.elementsNamed("Events")) {
		for (event in list.elementsNamed("Event")) {
			var eventType = event.get("type");
			if (eventScripts.exists(eventType)) {
				var n = eventScripts.get(eventType).call("getItemNameFromXML", [event]);
				for (i => item in modchartItems) {
					if (item.name == n) {
						var e = eventScripts.get(eventType).call("createEventGame", [eventTypes.indexOf(eventType), event, i]);
						events.push(e);
						break;
					}
				}
			}
		}
	}
	for (name => script in itemScripts) {
		script.call("postXMLLoadGame", [xml]);
	}

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
			if (eventUpdateFuncs[e.type](curStepFloat, e)) {
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
	loadEvents();
}