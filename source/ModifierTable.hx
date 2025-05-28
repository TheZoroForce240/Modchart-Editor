//
import Modifier;

class ModifierTable {
    public function new() {}

    public var modifiers:Array<Dynamic> = [];
    public var modTable:Array<Dynamic> = [];

    public var shaderPool:Array<Dynamic> = [];
    public var vertTable:Array<Dynamic> = [];
    public var fragTable:Array<Dynamic> = [];

    public function addModifier(mod:Modifier) {
        modifiers.push(mod);
    }

    public function init() {
        construct();
        generateShaders();
    }

    public function construct() {
        list = [];
        for(p in 0...PlayState.SONG.strumLines.length) {
            modTable.push([]);
            for (mod in modifiers) {
                mod.lastValues.push([]);
                for (sub in mod.subMods) sub.lastValues.push([]);
            }

            var keyCount:Int = 4;
            for (i in 0...keyCount) {
                modTable[p].push([]);
                for (mod in modifiers) {
                    if ((mod.strumLineID == -1 || mod.strumLineID == p) && (mod.strumID == -1 || mod.strumID == i)) {
                        modTable[p][i].push(mod);
                    }
                    mod.lastValues[p][i] = Math.NEGATIVE_INFINITY;
                    for (sub in mod.subMods) sub.lastValues[p][i] = Math.NEGATIVE_INFINITY;
                }
            }
        }
    }

    public function applyValuesToShader(shader:CustomShader, strumLineID:Int, strumID:Int) {
        for (mod in modTable[strumLineID][strumID]) {
            //only update value if needed
            if (mod.lastValues[strumLineID][strumID] != mod.value) {
                mod.lastValues[strumLineID][strumID] = mod.value;
                shader.hset(mod.shaderName, mod.value);
            }
            
            for (sub in mod.subMods) {
                if (sub.lastValues[strumLineID][strumID] != sub.value) {
                    sub.lastValues[strumLineID][strumID] = sub.value;
                    shader.hset(sub.shaderName, sub.value);
                }
            }
        }
    }

    public function getShader(strumLineID:Int, strumID:Int) {
        var pool = shaderPool[strumLineID][strumID];

        if (pool.length < 1) {
            return createShader(strumLineID, strumID);
        } else {
            var shader = pool.pop();
            return shader;
        }
    }
    public function putShader(shader:CustomShader, strumLineID:Int, strumID:Int) {
        var pool = shaderPool[strumLineID][strumID];
        pool.push(shader);
    }

    public function createShader(strumLineID:Int, strumID:Int) {
        var shader = new FunkinShader(fragTable[strumLineID][strumID], vertTable[strumLineID][strumID]);
        shader.data.vertexID.value = [0, 1, 2, 3];
        return shader;
    }
    
    public function generateShaders() {
        var baseShaderName = "notePerspective";
        var fragShaderPath = Paths.fragShader(baseShaderName);
        var vertShaderPath = Paths.vertShader(baseShaderName);
        var baseFragCode = Assets.exists(fragShaderPath) ? Assets.getText(fragShaderPath) : null;
        var baseVertCode = Assets.exists(vertShaderPath) ? Assets.getText(vertShaderPath) : null;

        for(p in 0...PlayState.SONG.strumLines.length) {
            vertTable.push([]);
            fragTable.push([]);
            shaderPool.push([]);

            var keyCount:Int = 4;
            for (i in 0...keyCount) {

                var data = {
                    vertUniforms: "",
                    vertFunctions: "",
                    fragUniforms: "",
                    fragFunctions: "",
                }

                for (mod in modTable[p][i]) {
                    mod.setupShaderCode(data);
                }

                var vert = baseVertCode;
                vert = StringTools.replace(vert, "#pragma modifierUniforms", data.vertUniforms);
                vert = StringTools.replace(vert, "#pragma modifierFunctions", data.vertFunctions);

                var frag = baseFragCode;
                frag = StringTools.replace(frag, "#pragma modifierUniforms", data.fragUniforms);
                frag = StringTools.replace(frag, "#pragma modifierFunctions", data.fragFunctions);

                vertTable[p].push(vert);
                fragTable[p].push(frag);
                shaderPool[p].push([]);
            }
        }
    }
}