package shaders;
import webgl.shaders.Shader;
import webgl.shaders.ShaderAttribute;
import webgl.shaders.ShaderTextureUniform;
import webgl.shaders.ShaderUniform;

import Html5Dom;

/**
 * ...
 * @author 
 */

class UpdateVelocitiesShader extends Shader
{
	public var positionsUniform : ShaderTextureUniform;
	public var velocitiesUniform : ShaderTextureUniform;
	public var worldWidthUniform : ShaderUniform;
	public var worldHeightUniform : ShaderUniform;
	public var bounceFrictionUniform : ShaderUniform;
	
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
		bounceFrictionUniform = new ShaderUniform(this, "bounceFriction");
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
			uniform float bounceFriction;
			
			uniform sampler2D positions;
			uniform sampler2D velocities;
			
			varying vec2 vTexCoord;

			const float gravity = 0.01;
			
			void main(void) 
			{
				vec2 pos = texture2D(positions, vTexCoord).xy;
				vec2 vel = texture2D(velocities, vTexCoord).xy;
				
				pos += vel;				
				vel.y += gravity;
				
				if (pos.y < -worldH) { vel.y *= -bounceFriction; }
				else if (pos.y > worldH) { vel.y *= -bounceFriction; }
				if (pos.x < -worldW) { vel.x *= -bounceFriction; }
				else if (pos.x > worldW) { vel.x *= -bounceFriction; }
				
				gl_FragColor = vec4(vel,0., 1.);				
			}
		";		
	}	
}