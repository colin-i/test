import haxe.macro.Context;
import haxe.macro.Expr.Binop;
import haxe.macro.Printer;
import haxe.macro.Type;
import haxe.macro.TypedExprTools;

/**
 * Skeleton Haxe -> AS generator (macro, walks the typed AST).
 * Install:
 *   haxelib dev hxas /path/to/this/folder
 *
 * Usage:
 *   haxe -lib hxas -main Main --no-output --macro 'Hx_As.init()' [Flags]
 *
 * Flags:
 *   -D as_out=<file>   write the AS translation to <file>
 *   -D txt_out=<file>  write the typed AST as plain Haxe-like text to <file>
 *   -D txt_out_raw     dump the raw TXxx enum tree instead (Std.string)
 *
 * UNTESTED skeleton: written against the Haxe 4 macro API. Expect to adjust.
 * Not handled yet (a warning is printed): switch, try/catch, enums, interfaces,
 * super.method() calls, ternary-style `if` used as a value, array/string API mapping.
 */
class Hx_As {
	static var printer = new Printer();
	static var superName:Null<String> = null;

	public static function init() {
		Context.onGenerate(generate);
	}

	// User classes have relative file positions (-cp .), std ones are absolute paths.
	static function isUser(c:ClassType):Bool {
		if (c.isExtern || c.isInterface) return false;
		var file = Context.getPosInfos(c.pos).file;
		return !haxe.io.Path.isAbsolute(file);
	}

	static function generate(types:Array<Type>) {
		var asPath = Context.definedValue("as_out");
		var txtPath = Context.definedValue("txt_out");
		if (asPath == null && txtPath == null) return;

		var out = new StringBuf();
		var txt = new StringBuf();
		var entry:Null<String> = null;

		for (t in types) {
			switch t {
				case TInst(r, _):
					var c = r.get();
					if (!isUser(c)) continue;
					if (asPath != null) genClass(c, out);
					if (txtPath != null) genTxt(c, txt);
					for (f in c.statics.get())
						if (f.name == "main") entry = c.name;
				default:
			}
		}

		if (asPath != null) {
			if (entry != null) out.add('$entry.main();\n');
			sys.io.File.saveContent(asPath, out.toString());
		}
		if (txtPath != null)
			sys.io.File.saveContent(txtPath, txt.toString());
	}

	// Plain typed-AST dump: "<field> = <Haxe-like body>" per field.
	static function genTxt(c:ClassType, out:StringBuf) {
		var raw = Context.defined("raw");
		out.add('// ${c.name}\n');
		var fs = c.statics.get().concat(c.fields.get());
		if (c.constructor != null) fs.unshift(c.constructor.get());
		for (f in fs) {
			var e = f.expr();
			if (e != null) out.add('${f.name} = ' + (raw ? Std.string(e.expr) : TypedExprTools.toString(e, true)) + "\n");
		}
		out.add("\n");
	}

	static function genClass(c:ClassType, out:StringBuf) {
		var name = c.name;
		superName = c.superClass != null ? c.superClass.t.get().name : null;

		// constructor
		var ctor = c.constructor != null ? c.constructor.get() : null;
		var ctorExpr = ctor != null ? ctor.expr() : null;
		if (ctorExpr != null) {
			switch ctorExpr.expr {
				case TFunction(tf): out.add('function $name(${args(tf)}) ' + body(tf.expr, 0) + "\n");
				default:
			}
		} else {
			out.add('function $name() {}\n');
		}
		if (superName != null) out.add('$name.prototype = new $superName();\n'); // TODO: must run before methods are assigned and after Super is defined

		// instance methods
		for (f in c.fields.get()) {
			switch f.kind {
				case FMethod(_):
					var e = f.expr();
					if (e == null) continue;
					switch e.expr {
						case TFunction(tf):
							out.add('$name.prototype.${f.name} = function(${args(tf)}) ' + body(tf.expr, 0) + ";\n");
						default:
					}
				default: // instance vars are assigned in the constructor
			}
		}

		// statics
		for (f in c.statics.get()) {
			var e = f.expr();
			if (e == null) continue;
			switch e.expr {
				case TFunction(tf):
					out.add('$name.${f.name} = function(${args(tf)}) ' + body(tf.expr, 0) + ";\n");
				default:
					out.add('$name.${f.name} = ' + expr(e, 0) + ";\n");
			}
		}
	}

	static function args(tf:TFunc):String
		return tf.args.map(a -> a.v.name).join(", ");

	static function tabs(n:Int):String
		return StringTools.lpad("", "\t", n);

	// Always yields "{ ... }" even if the source branch was a single expression.
	static function body(e:TypedExpr, ind:Int):String {
		return switch e.expr {
			case TBlock(_): expr(e, ind);
			default: "{\n" + tabs(ind + 1) + stmt(e, ind + 1) + "\n" + tabs(ind) + "}";
		}
	}

	static function stmt(e:TypedExpr, ind:Int):String {
		var s = expr(e, ind);
		return StringTools.endsWith(s, "}") ? s : s + ";";
	}

	static function unsupported(e:TypedExpr):String {
		var what = Std.string(e.expr).split("(")[0];
		Context.warning('as: unsupported $what', e.pos);
		return '/* unsupported: $what */';
	}

	static function isTrace(e:TypedExpr):Bool {
		return switch e.expr {
			case TField(_, FStatic(c, cf)): c.get().module == "haxe.Log" && cf.get().name == "trace";
			default: false;
		}
	}

	static function expr(e:TypedExpr, ind:Int):String {
		return switch e.expr {
			// ---- constants
			case TConst(c):
				switch c {
					case TInt(i): Std.string(i);
					case TFloat(s): s;
					case TString(s): haxe.Json.stringify(s);
					case TBool(b): b ? "true" : "false";
					case TNull: "null";
					case TThis: "this";
					case TSuper: superName;
				}
			case TLocal(v): v.name; // TODO: rename shadowed locals (AS vars are function-scoped)
			case TParenthesis(x): "(" + expr(x, ind) + ")";
			case TMeta(_, x): expr(x, ind);
			case TCast(x, _): expr(x, ind);

			// ---- declarations / blocks
			case TVar(v, init):
				init == null ? 'var ${v.name}' : 'var ${v.name} = ' + expr(init, ind);
			case TBlock(el):
				var s = "{\n";
				for (x in el) s += tabs(ind + 1) + stmt(x, ind + 1) + "\n";
				s + tabs(ind) + "}";

			// ---- operators
			case TBinop(op, a, b):
				expr(a, ind) + " " + printer.printBinop(op) + " " + expr(b, ind);
			case TUnop(op, postFix, x):
				postFix ? expr(x, ind) + printer.printUnop(op) : printer.printUnop(op) + expr(x, ind);

			// ---- member access
			case TField(x, fa):
				switch fa {
					case FStatic(c, cf): c.get().name + "." + cf.get().name;
					case FInstance(_, _, cf): expr(x, ind) + "." + cf.get().name;
					case FAnon(cf): expr(x, ind) + "." + cf.get().name;
					case FClosure(_, cf): expr(x, ind) + "." + cf.get().name; // TODO: needs delegate/bind in AS
					case FDynamic(s): expr(x, ind) + "." + s;
					default: unsupported(e);
				}
			case TTypeExpr(TClassDecl(c)): c.get().name;
			case TArray(a, i): expr(a, ind) + "[" + expr(i, ind) + "]";
			case TArrayDecl(el): "[" + el.map(x -> expr(x, ind)).join(", ") + "]";
			case TObjectDecl(fields):
				"{" + fields.map(f -> f.name + ": " + expr(f.expr, ind)).join(", ") + "}";

			// ---- calls
			case TCall(f, a):
				if (isTrace(f)) {
					// Haxe passes (value, posInfos): keep only the value
					"trace(" + expr(a[0], ind) + ")";
				} else switch f.expr {
					case TConst(TSuper):
						var rest = a.map(x -> expr(x, ind));
						rest.unshift("this");
						superName + ".call(" + rest.join(", ") + ")";
					default:
						expr(f, ind) + "(" + a.map(x -> expr(x, ind)).join(", ") + ")";
				}
			case TNew(c, _, a):
				"new " + c.get().name + "(" + a.map(x -> expr(x, ind)).join(", ") + ")";
			case TFunction(tf):
				"function(" + args(tf) + ") " + body(tf.expr, ind);

			// ---- control flow
			case TIf(cond, th, el):
				var s = "if (" + expr(cond, ind) + ") " + body(th, ind);
				if (el != null) {
					s += switch el.expr {
						case TIf(_, _, _): " else " + expr(el, ind);
						default: " else " + body(el, ind);
					}
				}
				s;
			case TWhile(cond, b, normal):
				normal ? "while (" + expr(cond, ind) + ") " + body(b, ind)
					: "do " + body(b, ind) + " while (" + expr(cond, ind) + ")";
			case TFor(v, it, b):
				var range = intRange(it);
				if (range == null) unsupported(e);
				else {
					var n = v.name;
					'for (var $n = ' + expr(range.a, ind) + '; $n < ' + expr(range.b, ind) + '; $n++) ' + body(b, ind);
				}
			case TReturn(x): x == null ? "return" : "return " + expr(x, ind);
			case TBreak: "break";
			case TContinue: "continue";
			case TThrow(x): "throw " + expr(x, ind);

			default: unsupported(e);
		}
	}

	// `a...b` is either still TBinop(OpInterval) or already `new IntIterator(a, b)`.
	static function intRange(it:TypedExpr):Null<{a:TypedExpr, b:TypedExpr}> {
		return switch it.expr {
			case TBinop(OpInterval, a, b): {a: a, b: b};
			case TNew(c, _, [a, b]) if (c.get().name == "IntIterator"): {a: a, b: b};
			case TParenthesis(x): intRange(x);
			default: null;
		}
	}
}
