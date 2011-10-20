package webgl.shaders;

import Html5Dom;
import webgl.textures.Texture2D;

/**
 * ...
 * @author 
 */

class ShaderUniform
{
	public var shader : Shader;
	public var name : String;
	public var location : WebGLUniformLocation;
	
	private var gl : WebGLRenderingContext;

	public function new(shader:Shader, name:String) 
	{
		this.shader = shader;
		this.name = name;
		this.gl = shader.gl;		
		location = gl.getUniformLocation(shader.program, name);
	}
	
	public function setTexture(textureSlot:GLint, i:Int, value:Texture2D) : Void
	{
		shader.use();
		gl.uniform1i(location, i);
		gl.activeTexture(textureSlot);
		gl.bindTexture(gl.TEXTURE_2D, value.texture);
	}
	
	public function setInt(value:Int):Void
	{
		shader.use();
		gl.uniform1i(location, value);		
	}	
	
	public function setFloat(value:Float):Void
	{
		shader.use();
		gl.uniform1f(location, value);		
	}	
	
	public function setMatrix(value:Float32Array):Void
	{
		shader.use();
		gl.uniformMatrix4fv(location, false, value);
	}	
	
}