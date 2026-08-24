shader_type spatial;
#include "psx.gdshaderinc"

void fragment() {
	PipelineInput input;
	input.fragcoord = FRAGCOORD;
	input.uv = UV;
	input.vert_color = COLOR;
	PipelineOutput res = pipeline_opaque(input);
	APPLY(res);
}