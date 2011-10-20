package ;

import Html5Dom;
import js.Lib;
import shaders.RenderPointsShader;
import shaders.UpdatePositionsShader;
import shaders.UpdateVelocitiesShader;
import webgl.geom.PointCloud2D;
import webgl.geom.FullscreenQuad;
import webgl.geom.PointCloud2D;
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
	private var positionsDB : DoubleBufferedRenderTarget2D;
	private var velocitiesDB : DoubleBufferedRenderTarget2D;
	
	private var quad : FullscreenQuad;
	private var cloud : PointCloud2D;
	
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
		positionsDB = new DoubleBufferedRenderTarget2D(gl);
		velocitiesDB = new DoubleBufferedRenderTarget2D(gl);		
		quad = new FullscreenQuad(gl);
		cloud = new PointCloud2D(gl);
		
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
	
		positionsDB.bufferA.initFromFloats(texWidth, texHeight, positions);
		positionsDB.bufferB.initFromFloats(texWidth, texHeight, positions);
		velocitiesDB.bufferA.initFromFloats(texWidth, texHeight, velocities);
		velocitiesDB.bufferB.initFromFloats(texWidth, texHeight, velocities);
		
		positionsDB.bufferA.setupFBO();
		positionsDB.bufferB.setupFBO();
		velocitiesDB.bufferA.setupFBO();
		velocitiesDB.bufferB.setupFBO();
	}
	
	private function setupRenderShader() : Void	
	{
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

		cloud.initFromData(new Float32Array(vertices));
		
		// Orthographic rendering
		var prMatrix = new Mat4();
		prMatrix.ortho(canvasManager.canvas.width / - 2, canvasManager.canvas.height / 2, canvasManager.canvas.width / 2, canvasManager.canvas.height / - 2, -10000, 10000);		
		renderShader.perspectiveMatrix.setMatrix(prMatrix.toFloat32Array());
	}
	
	public function update():Void 
	{		
		// Update
		updatePositions();
		updateVelocities();
		
		// Render
		drawScene();
		
		// Swap our double buffers
		positionsDB.swap();
		velocitiesDB.swap();
	}
	
	private function updatePositions(): Void
	{
		// Limit to the size of our offscreen buffers
		gl.viewport(0, 0, texWidth, texHeight);	
		
		// Update shader params
		updatePositionsShader.use();		
		updatePositionsShader.worldWidthUniform.setFloat(canvasManager.canvas.width/2);
		updatePositionsShader.worldHeightUniform.setFloat(canvasManager.canvas.height / 2);
		updatePositionsShader.positionsUniform.setTexture(positionsDB.front);
		updatePositionsShader.velocitiesUniform.setTexture(velocitiesDB.front);	
		updatePositionsShader.vertexPosition.setBuffer(quad.vertexBuffer);
		updatePositionsShader.vertexTextureCoord.setBuffer(quad.texCoordBuffer);	
		
		// Render updates to back buffer
		positionsDB.back.bind();		
		quad.render();
		positionsDB.back.unbind();
	}
	
	private function updateVelocities() : Void
	{
		// Limit to the size of our offscreen buffers
		gl.viewport(0, 0, texWidth, texHeight);	
		
		// Update shader params
		updateVelocitiesShader.use();		
		updateVelocitiesShader.worldWidthUniform.setFloat(canvasManager.canvas.width/2);
		updateVelocitiesShader.worldHeightUniform.setFloat(canvasManager.canvas.height / 2);				
		updateVelocitiesShader.positionsUniform.setTexture(positionsDB.front);
		updateVelocitiesShader.velocitiesUniform.setTexture(velocitiesDB.front);
		updateVelocitiesShader.vertexPosition.setBuffer(quad.vertexBuffer);
		updateVelocitiesShader.vertexTextureCoord.setBuffer(quad.texCoordBuffer);
		updateVelocitiesShader.bounceFrictionUniform.setFloat(wallFriction);
		
		// Render updates to back buffer
		velocitiesDB.back.bind();
		quad.render();
		velocitiesDB.back.unbind();
	}
	
	private function drawScene()
	{
		// Set the viewport back to the full canvas size and clear
		gl.viewport(0, 0,  Std.int(canvasManager.canvas.width),  Std.int(canvasManager.canvas.height));
		gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
		
		// Update shader params
		renderShader.use();
		renderShader.vertexPosition.setBuffer(cloud.vertexBuffer);
		renderShader.viewMatrix.setMatrix(mvMatrix.toFloat32Array());		
		renderShader.positionsTexture.setTexture(positionsDB.back);
		renderShader.pointSize.setFloat(particleSize);	

		// Render all the points
		gl.enable(gl.BLEND);
		cloud.render();
		gl.disable(gl.BLEND);	
	}	
}