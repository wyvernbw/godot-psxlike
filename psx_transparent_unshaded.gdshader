shader_type spatial;
render_mode unshaded;
#include "psx.gdshaderinc"

uniform sampler2D screen_tex: hint_screen_texture, filter_nearest;

void fragment() {
	PipelineInput input;
	input.fragcoord = FRAGCOORD;
	input.uv = UV;
	input.vert_color = COLOR;
	PipelineOutput res = pipeline_transparent(input, screen_tex, SCREEN_UV);
	APPLY(res);
}