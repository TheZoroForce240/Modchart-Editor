//

class Vec4 {
    public var x:Float = 0;
    public var y:Float = 0;
    public var z:Float = 0;
    public var w:Float = 0;

    public function new(X:Float, Y:Float, Z:Float, W:Float) {
        x = X;
        y = Y;
        z = Z;
        w = W;
    }

    public function normalize() {
        var mag:Float = Math.sqrt((x * x) + (y * y) + (z * z) + (w * w) );
        if (mag != 0) {
            x = x / mag;
            y = y / mag;
            z = z / mag;
            w = w / mag;
        }
    }

    public function cross(a:Vec4, b:Vec4) {
        x = a.y * b.z - a.z * b.y;
        y = a.z * b.x - a.x * b.z;
        z = a.x * b.y - a.y * b.x;
        w = 1.0;
    }

    public function dot(vec:Vec4) {
        return x * vec.x + y * vec.y + z * vec.z;
    }
}

function createVec4(X:Float, Y:Float, Z:Float, W:Float) {
    return new Vec4(X, Y, Z, W);
}