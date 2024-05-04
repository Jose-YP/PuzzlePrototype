shader_type canvas_item;

uniform vec4 makeTransparent : source_color = vec4(1,1,1,1);
uniform vec4 otherColor: source_color = vec4(1,1,1,1);
uniform float margin: hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float otherColorMix: hint_range(0.0, 1.0, 0.1) = .1;

void vertex() {
	COLOR = vec4(1);
}

void fragment() {
	bool made_transparent = false;
	vec4 input = texture(TEXTURE, UV);
	
	if (input == makeTransparent){
		COLOR = vec4(0.0,0.0,0.0,0.0);
		made_transparent = true;
		}
	
	if (margin != 0.0){
		vec3 margin_input = vec3(makeTransparent.r + margin,makeTransparent.g + margin, input.b + margin);
		bool red_check = input.r <= margin_input.r;
		bool green_check = input.g <= margin_input.g;
		bool blue_check = input.b <= margin_input.b;
		if (red_check && green_check && blue_check){
			COLOR = vec4(0.0,0.0,0.0,0.0);
			made_transparent = true;
		}
		
		if (made_transparent == false){
			vec4 finalColor = vec4(mix(input, otherColor, otherColorMix));
			COLOR = finalColor;
		}
		
	}
	
	// Called for every pixel the material is visible on.
}
