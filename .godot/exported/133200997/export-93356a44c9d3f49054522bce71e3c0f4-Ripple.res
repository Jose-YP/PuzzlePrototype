RSRC                    ShaderMaterial            ��������                                                  resource_local_to_scene    resource_name    code    script    shader    shader_parameter/strength    shader_parameter/center    shader_parameter/radius    shader_parameter/aberration    shader_parameter/width    shader_parameter/feather           local://Shader_cx7ik �         local://ShaderMaterial_10vd3 �         Shader            shader_type canvas_item;

uniform float strength: hint_range(0.0, 0.1, 0.001) = 0.08;
uniform vec2 center = vec2(0.5, 0.5);
uniform float radius: hint_range(0.0, 2.0, 0.001) = 0.25;

uniform float aberration: hint_range(0.0, 1.0, 0.001) = 0.425;
uniform float width: hint_range(0.0, 0.1, 0.0001) = 0.04;
uniform float feather: hint_range(0.0, 1.0, 0.001) = 0.135;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 st = SCREEN_UV;
	float aspect_ratio = SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
	vec2 scaled_st = (st -vec2(0.0, 0.5)) / vec2(1.0, aspect_ratio) + vec2(0,0.5);
	vec2 center_corr = (center -vec2(0.0, 0.5)) / vec2(1.0, aspect_ratio) + vec2(0,0.5);
	vec2 dist_center = scaled_st - center_corr;
	float mask =  (1.0 - smoothstep(radius-feather, radius, length(dist_center))) * smoothstep(radius - width - feather, radius-width , length(dist_center));
	vec2 offset = normalize(dist_center)*strength*mask;
	vec2 biased_st = scaled_st - offset;
	
	vec2 abber_vec = offset*aberration*mask;
	
	vec2 final_st = st*(1.0-mask) + biased_st*mask;

	vec4 red = texture(SCREEN_TEXTURE, final_st + abber_vec);
	vec4 blue = texture(SCREEN_TEXTURE, final_st - abber_vec);
	vec4 ori = texture(SCREEN_TEXTURE, final_st);
	COLOR = vec4(red.r, ori.g, blue.b, 1.0);
}          ShaderMaterial                    )   {�G�z�?   
      ?   ?             )   333333�?	   )   {�G�z�?
   )   H�z�G�?      RSRC