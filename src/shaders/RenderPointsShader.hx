package shaders;

import Html5Dom;
import webgl.shaders.Shader;
import webgl.shaders.ShaderAttribute;
import webgl.shaders.ShaderUniform;

/**
 * ...
 * @author 
 */

class RenderPointsShader extends Shader
{
	public var vertexPosition : ShaderAttribute;	
	public var viewMatrix : ShaderUniform;
	public var perspectiveMatrix : ShaderUniform;
	public var positionsTexture : ShaderUniform;
	public var pointSize : ShaderUniform;
	
	public function new(gl:WebGLRenderingContext)
	{			
		super(gl);	
		setupAtribsAndUniforms();
	}
	
	public function setupAtribsAndUniforms() : Void
	{
		viewMatrix = new ShaderUniform(this, "mvMatrix");
		perspectiveMatrix = new ShaderUniform(this, "prMatrix");
		positionsTexture = new ShaderUniform(this, "positions");
		vertexPosition = new ShaderAttribute(this, "vertexPosition");
		pointSize = new ShaderUniform(this, "pointSize");
	}
	
	override private function getVertexSrc() : String
	{
		return 
		"
			
			uniform mat4 mvMatrix;
			uniform float pointSize;
			uniform mat4 prMatrix;
			uniform sampler2D positions;
			
			varying vec4 color;
			
			attribute vec2 vertexPosition;
			
			void main(void) 
			{
				gl_Position = prMatrix * mvMatrix * texture2D(positions, vertexPosition);
				//gl_Position = texture2D(positions, aPoints)*.500;
				//gl_Position = vec4(0.0+0.5, 0.0+0.5, 0., 1.);
				gl_PointSize = pointSize;
				color = vec4( .1, .5, 1., .3 );
			}
		";		
	}
	
	override private function getFragmentSrc() : String
	{
		return 
		"
			#ifdef GL_ES
			precision highp float;
			#endif
			
			varying vec4 color;
			
			void main(void) 
			{
			   gl_FragColor = color;
			}
		";		
	}
	
}