shader_type canvas_item;

uniform float hp_ratio : hint_range(0.0, 1.0) = 1.0;
uniform float qi_ratio : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	
	// UV ranges normalized to 0.0 - 1.0 based on texture size 1024 x 341
	float hp_x_start = 115.0 / 1024.0;
	float hp_x_end = 744.0 / 1024.0;
	float hp_y_start = 125.0 / 341.0;
	float hp_y_end = 166.0 / 341.0;
	
	float qi_x_start = 81.0 / 1024.0;
	float qi_x_end = 960.0 / 1024.0;
	float qi_y_start = 201.0 / 341.0;
	float qi_y_end = 240.0 / 341.0;
	
	// Check if pixel is inside HP bar
	if (UV.y >= hp_y_start && UV.y <= hp_y_end && UV.x >= hp_x_start && UV.x <= hp_x_end) {
		// Calculate vertical center of HP bar
		float hp_y_center = (hp_y_start + hp_y_end) / 2.0;
		float hp_y_half_height = (hp_y_end - hp_y_start) / 2.0;
		
		// Chevron shape offset: extends to the right at the center, recedes at top/bottom
		// The tip of the chevron extends by about 15 pixels
		float chevron_offset = (1.0 - abs(UV.y - hp_y_center) / hp_y_half_height) * (15.0 / 1024.0);
		
		// Calculate the threshold UV.x for the current HP ratio
		float threshold_x = hp_x_start + (hp_x_end - hp_x_start) * hp_ratio + chevron_offset;
		
		if (UV.x > threshold_x) {
			// Deplete the pixel: dim it to represent the empty slot
			// Blend with dark background color Color(0.05, 0.04, 0.04)
			color.rgb = mix(color.rgb, vec3(0.08, 0.06, 0.05), 0.92);
		}
	}
	
	// Check if pixel is inside Qi bar
	if (UV.y >= qi_y_start && UV.y <= qi_y_end && UV.x >= qi_x_start && UV.x <= qi_x_end) {
		// Brush stroke shape: add wave/noise to the threshold
		// Wave offset based on UV.y
		float wave_offset = (sin(UV.y * 120.0) * 6.0 + cos(UV.y * 320.0) * 3.0) / 1024.0;
		
		// Calculate the threshold UV.x for the current Qi ratio
		float threshold_x = qi_x_start + (qi_x_end - qi_x_start) * qi_ratio + wave_offset;
		
		if (UV.x > threshold_x) {
			// Deplete the pixel: dim it to represent the empty slot
			// Blend with very dark background color Color(0.03, 0.03, 0.03)
			color.rgb = mix(color.rgb, vec3(0.04, 0.04, 0.04), 0.94);
		}
	}
	
	COLOR = color;
}
