//
import SubModifier;
import funkin.backend.utils.IniUtil;

class Modifier {
    public var name:String;
    public var value:Float = 0.0;
    public var strumLineID:Int = -1;
    public var strumID:Int = -1;
    public var subMods:Array<SubModifier> = [];

    public var shaderName:String;
    public var shaderFile:String = null;

    public function new(n:String, v:Float, slid:Int, sid:Int, submods:Array<SubModifier>, ?shaderfile:String = null) {
        name = n;
        shaderName = n + "_value";
        value = v;
        strumLineID = slid;
        strumID = sid;
        subMods = submods;
        shaderFile = shaderfile;

        /*
        var iniData = ["" => ""];
        if (Assets.exists("modifiers/"+shaderFile+".ini")) {
            iniData = IniUtil.parseAsset("modifiers/"+shaderFile+".ini");
        }
        */

        for (sub in subMods) {
            sub.shaderName = n + "_" + sub.name;
        }
    }

    public function setupShaderCode(shaderData:Dynamic) {
        if (shaderFile == null) return;

        
        shaderData.vertUniforms += "uniform float " + shaderName + ";\n";
        for (submod in subMods) {
            shaderData.vertUniforms += "uniform float " + submod.shaderName + ";\n";
        }

        if (Assets.exists("modifiers/"+shaderFile+".vert")) {
            var vertCode = Assets.getText("modifiers/"+shaderFile+".vert");
            vertCode = StringTools.replace(vertCode, "_value_", shaderName);
            for (submod in subMods) {
                vertCode = StringTools.replace(vertCode, "_" + submod.name + "_", submod.shaderName);
            }

            shaderData.vertFunctions += vertCode + "\n";
        }

        /*
        if (Assets.exists("modifiers/"+shaderFile+".frag")) {
            var fragCode = Assets.getText("modifiers/"+shaderFile+".frag");
            fragCode = StringTools.replace(fragCode, "_value_", shaderName);
            for (submod in subMods) {
                fragCode = StringTools.replace(fragCode, "_" + submod.name + "_", submod.shaderName);
            }

            shaderData.fragFunctions += fragCode + "\n";
        }
        */
    }
}