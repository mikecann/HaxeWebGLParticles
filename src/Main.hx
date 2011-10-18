package ;

import Html5Dom;
import haxe.Timer;
import js.Lib;
import js.Dom;
import js.JQuery;
import utils.ConsoleTracing;
import utils.js.Framerate;
import utils.RequestAnimationFrame;
import webgl.textures.Texture2D;

/**
 * ...
 * @author MikeCann
 */

class Main 
{		
	// Privates
	inline private var gl(default, null) : WebGLRenderingContext;
	
	private var canvas : HTMLCanvasElement;		
	private var _gpuParticles2 : GPUParticles2;	
	private var framerate : Framerate;
	
	public function new()
	{			
		Lib.window.onload = onWindowLoaded;
	}
	
	private function onWindowLoaded(e:Dynamic):Void 
	{		
		canvas = cast Lib.document.getElementById("canvas");
		if (!setupGL()) return;
		
		framerate = new Framerate();		
		_gpuParticles2 = new GPUParticles2(gl);		
		
		new JQuery("#numParticlesInp").val(_gpuParticles2.particleCount+"");
		new JQuery("#particleSizeInp").val(_gpuParticles2.particleSize+"");
		new JQuery("#wallFrictionInp").val(_gpuParticles2.wallFriction+"");
		new JQuery("#updateBtn").click(onUpdateButtonClicked);	
		
		tick();
	}
	
	private function setupGL() : Bool
	{
		try	{ gl = canvas.getContext("experimental-webgl"); } catch (e:DOMError){}					
		if ( gl == null) { trace("Unable to initialize WebGL. Your browser may not support it."); }		
		var ext = gl.getExtension("OES_texture_float");
		if ( !ext ) { Lib.alert("Your browser does not support OES_texture_float extension"); return false; }
		if (gl.getParameter(gl.MAX_VERTEX_TEXTURE_IMAGE_UNITS) == 0) { Lib.alert("Your browser does not support Vertex texture"); return false; }	
		return true;
	}
			
	private function onUpdateButtonClicked(e:JqEvent):Void 
	{
		var dontTex : Bool = new JQuery("#dontTexLookupChk").is(':checked');
		_gpuParticles2.particleCount = Std.parseInt(new JQuery("#numParticlesInp").val());
		_gpuParticles2.particleSize = Std.parseInt(new JQuery("#particleSizeInp").val());
		_gpuParticles2.wallFriction = Std.parseFloat(new JQuery("#wallFrictionInp").val());
		_gpuParticles2.reset();
	}
	
	private function tick() 
	{
		RequestAnimationFrame.request(tick);		
		_gpuParticles2.update();	
		framerate.inc();	
	}
	
	static function main() 
	{
		ConsoleTracing.setRedirection();
		new Main();
	}
	
}