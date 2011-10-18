package ;

import Html5Dom;
import js.Lib;

/**
 * ...
 * @author 
 */

class CanvasManager 
{
	public var canvas : HTMLCanvasElement;
	
	public var translateX:Float;
	public var translateY:Float;
	
	private var isMouseDown : Bool;
	private var lastMouseX:Float;
	private var lastMouseY:Float;
	private var system : GPUParticles2;
	private var gl : WebGLRenderingContext;
	
	public function new(system:GPUParticles2) 
	{
		this.system = system;		
		this.gl = system.gl;		
		
		translateX = translateY = 0;
		
		canvas = cast Lib.document.getElementById("canvas");
	  
		canvas.onmousedown = onCanvasMouseDown;	
		canvas.onmouseup = onCanvasMouseUp;				
		canvas.onmousemove = onCanvasMouseMove;	
	}
	
	private function onCanvasMouseDown(ev) : Void
	{
		isMouseDown = true;
		lastMouseX = ev.clientX;  
		lastMouseY = ev.clientY;
	}
	
	private function onCanvasMouseUp(ev) : Void
	{
		isMouseDown  = false;
	}
	
	private function onCanvasMouseMove(ev) : Void
	{
		if ( !isMouseDown ) return;
		
		translateX += ev.clientX - lastMouseX;
		translateY += ev.clientY - lastMouseY;
		lastMouseX = ev.clientX;
		lastMouseY = ev.clientY;
		
		system.mvMatrix.reset();
		system.mvMatrix.translate(translateX, translateY, 0);				
		
		// Rotate
		/*if ( ev.shiftKey ) {
		transl *= 1 + (ev.clientY - yOffs)/300;
		yRot = - xOffs + ev.clientX; }
		else {
		yRot = - xOffs + ev.clientX;  xRot = - yOffs + ev.clientY; }
		xOffs = ev.clientX;   yOffs = ev.clientY;*/
	}
	
}