package shaders;

import Html5Dom;
import webgl.shaders.Shader;
import webgl.shaders.ShaderAttribute;
import webgl.shaders.ShaderTextureUniform;
import webgl.shaders.ShaderUniform;

/**
 * ...
 * @author 
 */

class UpdatePositionsShader extends Shader
{	
	public var positionsUniform : ShaderTextureUniform;
	public var velocitiesUniform : ShaderTextureUniform;
	public var worldWidthUniform : ShaderUniform;
	public var worldHeightUniform : ShaderUniform;
	
	public var vertexPosition : ShaderAttribute;
	public var vertexTextureCoord : ShaderAttribute;
	
	public function new(gl:WebGLRenderingContext)
	{			
		super(gl);	
		vertexPosition = new ShaderAttribute(this, "aPos");
		vertexTextureCoord = new ShaderAttribute(this, "aTexCoord");
		positionsUniform = new ShaderTextureUniform(this, "positions", 0);
		velocitiesUniform = new ShaderTextureUniform(this, "velocities", 1);
		
		worldWidthUniform = new ShaderUniform(this, "worldW");
		worldHeightUniform = new ShaderUniform(this, "worldH");
	}
	
	override private function getVertexSrc() : String
	{
		return 
		"
			attribute vec2 aPos;
			attribute vec2 aTexCoord;
			
			varying   vec2 vTexCoord;
			
			void main(void) 
			{
				gl_Position = vec4(aPos, 0., 1.);
				vTexCoord = aTexCoord;
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
			
			uniform float worldW;
			uniform float worldH;
			uniform sampler2D positions;
			uniform sampler2D velocities;
			
			varying vec2 vTexCoord;
			
			void main(void) 
			{
				vec2 pos = texture2D(positions, vTexCoord).xy;
				vec2 vel = texture2D(velocities, vTexCoord).xy;
				
				pos += vel;						
				
				if (pos.y < -worldH) { pos.y = -worldH; }
				else if (pos.y > worldH) { pos.y = worldH; }
				if (pos.x < -worldW) { pos.x = -worldW; }
				else if (pos.x > worldW) { pos.x = worldW; }
				
				gl_FragColor = vec4(pos,0., 1.);				
			}
		";		
	}
}