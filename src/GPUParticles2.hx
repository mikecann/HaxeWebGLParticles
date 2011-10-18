package ;

import Html5Dom;
import js.Lib;
import shaders.RenderPointsShader;
import shaders.UpdatePositionsShader;
import shaders.UpdateVelocitiesShader;
import webgl.math.Mat4;
import webgl.textures.DoubleBufferedRenderTarget2D;
import webgl.textures.RenderTarget2D;
import webgl.textures.Texture2D;

/**
 * ...
 * @author 
 */

class GPUParticles2 
{		
	public var gl : WebGLRenderingContext;	
	
	public var particleCount : Int;
	public var particleSize : Int;
	public var wallFriction : Float;		
	public var mvMatrix : Mat4;	
	public var texWidth : Int;
	public var texHeight : Int;
	
	private var canvasManager : CanvasManager;
	private var updatePositionsShader : UpdatePositionsShader;
	private var updateVelocitiesShader : UpdateVelocitiesShader;
	private var renderShader : RenderPointsShader;
	private var positionsFBO : RenderTarget2D;
	private var velocitiesFBO : RenderTarget2D;
	
	public function new(gl:WebGLRenderingContext) 
	{
		this.gl = gl;				
		particleCount = 10000;
		particleSize = 2;
		wallFriction = 0.8;
		mvMatrix = new Mat4();

		canvasManager = new CanvasManager(this);		
		updatePositionsShader = new UpdatePositionsShader(gl);
		updateVelocitiesShader = new UpdateVelocitiesShader(gl);
		renderShader = new RenderPointsShader(gl);	
		positionsFBO = new RenderTarget2D(gl);
		velocitiesFBO = new RenderTarget2D(gl);
		
		reset();
		
	}	
	
	public function reset() : Void
	{				
		// Fist work out how big our positions and velocities textures need to be
		// in webgl they need to be a power of two
		calculateTexWidthAndHeight();		

		// Setup some bits
		setupInitialPositionsAndVelocities();					
		setupRenderShader();
		setupPositionAndVelocityUpdateShaders();
						
		// Im not sure why but apparently this has to go here		
		renderShader.positionsTexture.setInt(0);		
		
		// Black background with blending
		gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
		gl.clearColor(0, 0, 0, 1);
	}
	
	private function calculateTexWidthAndHeight():Void 
	{
		texWidth = texHeight = 2;
		
		while (texWidth * texHeight < particleCount)
		{
			texWidth *= 2;
			if (texWidth * texHeight >= particleCount) break;
			texHeight *= 2;
		}	
		
		trace("Texture width and height set to: " + texWidth + "x" + texHeight);
	}
	
	private function setupPositionAndVelocityUpdateShaders() : Void
	{
		updatePositionsShader.vertexPosition.setData(new Float32Array([ -1, -1, 0, 0, -1, 1, 0, 1, 1, -1, 1, 0, 1, 1, 1, 1]), 2, 16, 0);
		updatePositionsShader.vertexTextureCoord.setData(new Float32Array([ -1, -1, 0, 0, -1, 1, 0, 1, 1, -1, 1, 0, 1, 1, 1, 1]), 2, 16, 8);	
		
		updateVelocitiesShader.bounceFrictionUniform.setFloat(wallFriction);
		updateVelocitiesShader.vertexPosition.setData(new Float32Array([ -1, -1, 0, 0, -1, 1, 0, 1, 1, -1, 1, 0, 1, 1, 1, 1]), 2, 16, 0);
		updateVelocitiesShader.vertexTextureCoord.setData(new Float32Array([ -1, -1, 0, 0, -1, 1, 0, 1, 1, -1, 1, 0, 1, 1, 1, 1]), 2, 16, 8);	
	}
	
	private function setupInitialPositionsAndVelocities() : Void
	{
		var positions : Array<Float> = [];
		var velocities : Array<Float> = [];
		
		for (k in 0...texWidth*texHeight)
		{
			var ang = (180 / Math.PI) * Math.random();
			var dist = 0.1+Math.random();
			positions.push(Math.sin(ang)*dist*30);
			positions.push (Math.cos(ang)*dist*30);
			positions.push (0);			
			velocities.push((-4)+(Math.sin(ang)*dist*2)+Math.random()*8);
			velocities.push((-4)+(Math.cos(ang)*dist*2)+Math.random()*8);
			velocities.push(0);
		}	
		
		positionsFBO.initFromFloats(gl.TEXTURE0, texWidth, texHeight, positions);
		velocitiesFBO.initFromFloats(gl.TEXTURE1, texWidth, texHeight, velocities);		
		positionsFBO.setupFBO();
		velocitiesFBO.setupFBO();				
	}
	
	private function setupRenderShader() : Void	
	{
		// To be honest im not sure why this attribute HAS to point at 2 rather than 
		// just getting the attrib location as usual 
		var aPointsLoc = 2;
		gl.bindAttribLocation(renderShader.program, aPointsLoc, "vertexPosition");
		gl.linkProgram(renderShader.program);

		var vertices = [];
		var invTexW : Float = 1 / texWidth;
		var invTexH : Float = 1 / texHeight;
		var y : Float = invTexH / 2;
		while ( y < 1 )
		{
			var x : Float = invTexW / 2;
			while ( x < 1 )
			{
				vertices.push ( x );
				vertices.push ( y );
				x += invTexW;
			}
			y += invTexH;
		}		
		
		gl.enableVertexAttribArray( aPointsLoc );
		gl.bindBuffer(gl.ARRAY_BUFFER, gl.createBuffer());
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
		gl.vertexAttribPointer(aPointsLoc, 2, gl.FLOAT, false, 0, 0);
		
		renderShader.setupAtribsAndUniforms();			
		renderShader.pointSize.setFloat(particleSize);	
		
		// Orthographic rendering
		var prMatrix = new Mat4();
		prMatrix.ortho(canvasManager.canvas.width / - 2, canvasManager.canvas.height / 2, canvasManager.canvas.width / 2, canvasManager.canvas.height / - 2, -10000, 10000);		
		renderShader.perspectiveMatrix.setMatrix(prMatrix.toFloat32Array());
	}
	
	public function update():Void 
	{
		// Limit to the size of our offscreen buffers
		gl.viewport(0, 0, texWidth, texHeight);
	
		// Update positions
		updatePositionsShader.use();
		updatePositionsShader.worldWidthUniform.setFloat(canvasManager.canvas.width/2);
		updatePositionsShader.worldHeightUniform.setFloat(canvasManager.canvas.height / 2);
		updatePositionsShader.positionsUniform.setInt(0);
		updatePositionsShader.velocitiesUniform.setInt(1);
		positionsFBO.bind();
		gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
		positionsFBO.unbind();
		gl.flush();

		// Update velocities
		updateVelocitiesShader.use();
		updateVelocitiesShader.worldWidthUniform.setFloat(canvasManager.canvas.width/2);
		updateVelocitiesShader.worldHeightUniform.setFloat(canvasManager.canvas.height/2);
		updateVelocitiesShader.positionsUniform.setInt(0);
		updateVelocitiesShader.velocitiesUniform.setInt(1);
		velocitiesFBO.bind();
		gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
		velocitiesFBO.unbind();
		gl.flush();
	
		// Render it all
		drawScene();
	}
	
	function drawScene()
	{
		// Set the viewport back to the full canvas size and clear
		gl.viewport(0, 0,  Std.int(canvasManager.canvas.width),  Std.int(canvasManager.canvas.height));
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
		
		renderShader.use();
	
		// The mv matrix may have changed, reset it	
		renderShader.viewMatrix.setMatrix(mvMatrix.toFloat32Array());

		// Render all the points
		gl.enable(gl.BLEND);
		gl.drawArrays(gl.POINTS, 0, particleCount);
		gl.disable(gl.BLEND);
		gl.flush ();
	}	
}