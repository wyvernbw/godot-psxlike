render_mode vertex_lighting, unshaded, skip_vertex_transform;
// Converts a color from linear light gamma to sRGB gamma
vec3 from_linear(vec3 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB.rgb, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB.rgb, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB.rgb * vec3(12.92);

    return mix(higher, lower, cutoff);
}

// Converts a color from sRGB gamma to linear light gamma
vec3 to_linear(vec3 sRGB)
{
    bvec3 cutoff = lessThan(sRGB.rgb, vec3(0.04045));
    vec3 higher = pow((sRGB.rgb + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB.rgb/vec3(12.92);

    return mix(higher, lower, cutoff);
}

vec3 to_rgb5(vec3 color) {
	color.rgb *= 31.;
	color.rgb = round(color.rgb);
	color.rgb /= 31.;
	return color;
}

uniform sampler2D[10] textures;

instance uniform int tex_id;
instance uniform bool use_dither;

const int SHADING_FLAT = 0;
const int SHADING_GORAUD = 1;
instance uniform int shading: hint_enum("flat", "goraud") = 0;
instance uniform vec4 flat_color: source_color;
const int TEX_TEXTURED = 0;
const int TEX_UNTEXTURED = 1;
instance uniform int texturing: hint_enum("textured", "untextured") = 0;

instance uniform bool use_modulation = false;
instance uniform vec4 modulate_tint: source_color = vec4(0.5, 0.5, 0.5, 1.0);
instance uniform float modulate_brightness: hint_range(0.0, 1.0, 0.1);

const int ST_NONE = 0;
const int ST_AVG = 1;
const int ST_ADD = 2;
const int ST_SUB = 3;
const int ST_ADD_x25 = 4;
instance uniform int semi_transparency: hint_enum("None", "Average", "Add", "Subtract", "Add x0.25") = 0;

vec3 dither(vec3 color, vec2 fragcoord) {
	const int[16] DITHER = int[] (
    	-4,  0, -3,  1,
    	 2, -2,  3, -1,
    	-3,  1, -4,  0,
    	 3, -1,  2, -2
	);

	if (use_dither && (shading == SHADING_GORAUD || use_modulation)) {
		ivec2 coord = ivec2(fragcoord) % ivec2(4);
		int value = DITHER[coord.y*4 + coord.x];
		float valuef = float(value);
		color.rgb += vec3(valuef) / 255.;
	}
	return color;
}

varying vec4 clip_pos;
varying flat float depth;

instance uniform float depth_modifier: hint_range(-10.0, 10.0, 0.1);

// share these for every model 
global uniform float fog_far_plane: hint_range(0.0, 10.0, 0.1);
global uniform float fog_near_plane: hint_range(0.0, 10.0, 0.1);
global uniform vec4 fog_color: source_color;
global uniform bool fog_enabled = false;
global uniform int fog_kind;
const int FOG_MODULATION = 0;
const int FOG_SH = 1;
instance uniform bool fog_opt_out = false;
varying float fog_factor;
global uniform sampler2D lights;
global uniform vec4 ambient_light: source_color;
global uniform int light_count;

vec3 get_fog_color(vec3 base, float fog) {
	if (!fog_enabled || fog_opt_out) return base;
	fog = clamp(fog, 0.0, 1.0);
	float t = floor(fog * float(0x1000)) / float(0x1000); 
	return mix(base, fog_color.rgb, t);
}

vec3 psx_light(vec3 world_vert, vec3 normal) {
	if (shading != SHADING_GORAUD) return vec3(0.0);
	
	const int LIGHT_DIRECTIONAL = 0;
	const int LIGHT_POINT = 1;
	
	vec3 light = ambient_light.rgb;
	int buffer_len = textureSize(lights, 0).x;
	int stride = 3;
	for (int i = 0; i < light_count; i += 1) {
		int cursor = i*stride;
		vec3 meta = texelFetch(lights, ivec2(cursor, 0), 0).rgb;
		int type = int(meta.r);
		int visible = int(meta.g);
		if (visible == 0) continue;
		vec3 data = texelFetch(lights, ivec2(cursor+1, 0), 0).rgb;
		vec3 color = texelFetch(lights, ivec2(cursor+2, 0), 0).rgb;
		switch (type) {
			case LIGHT_DIRECTIONAL: {
				vec3 dir = data;
				light += clamp(dot(dir, normal), 0.0, 1.0) * color;
				break;
			}
			case LIGHT_POINT: {
				vec3 pos = data;
				float range = meta.b;
				float dist = distance(world_vert, pos);
				light += mix(color, vec3(0.0), clamp(dist / range, 0.0, 1.0));
				break;
			}
		};
	}
	return light;
}

void vertex() {
	vec4 world_space = MODEL_MATRIX * vec4(VERTEX, 1);
	vec4 clip = PROJECTION_MATRIX * VIEW_MATRIX * world_space;
	vec4 vertex = clip;
	
	vertex.xy = round(clip.xy / clip.w * VIEWPORT_SIZE.xy) / VIEWPORT_SIZE.xy * clip.w;
	POSITION = vertex;
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
    BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
    TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
	clip_pos = vertex;
	
	COLOR.rgb *= psx_light(world_space.xyz, NORMAL);
	
	UV = UV * vertex.w; 
	
	if (shading == SHADING_FLAT) {
		COLOR = flat_color;
	}

	
	depth = clip.z / clip.w + depth_modifier / 100.;
		
	if (fog_enabled && !fog_opt_out) {
		float view_dist = distance(CAMERA_POSITION_WORLD, world_space.xyz);
		fog_factor = view_dist / (fog_far_plane - fog_near_plane);
		if (fog_kind == FOG_MODULATION) {
			COLOR.rgb = get_fog_color(COLOR.rgb, fog_factor);
		} else {
			fog_factor *= clip.w;
		}
	}
	
}

vec3 get_albedo(vec4 vert_color, sampler2D tex, vec2 uv) {
	if (texturing == TEX_UNTEXTURED) {
		switch (shading) {
			case SHADING_FLAT: {
				return from_linear(vert_color.rgb);
			}
			case SHADING_GORAUD: {
				return from_linear(vert_color.rgb * flat_color.rgb);
			}
		}
	}
	
	ivec2 texcoord = ivec2(uv * vec2(textureSize(textures[tex_id], 0).xy));
	vec3 color = texelFetch(textures[tex_id], texcoord, 0).rgb;
	
	if (use_modulation) {
		color.rgb *= 2.0 * from_linear(vert_color.rgb * modulate_tint.rgb);
		color.rgb += modulate_brightness;
	}

	return color;
}

vec3 apply_semi_transparency(vec3 albedo, sampler2D screen_tex, vec2 screen_uv) {
	#define SCREEN from_linear(texelFetch(screen_tex, screen_coord, 0).rgb)
	
	ivec2 screen_coord = ivec2(screen_uv * vec2(textureSize(screen_tex, 0)));
	switch (semi_transparency) {
		case ST_NONE: {
			return albedo;
		}
		case ST_AVG: {
			return SCREEN * 0.5 + albedo * 0.5;
		}
		case ST_ADD: {
			return SCREEN + albedo;
		}
		case ST_SUB: {
			return SCREEN - albedo;
		}
		case ST_ADD_x25: {
			return SCREEN + albedo * 0.25;
		}
	}
}

struct PipelineOutput {
	vec3 albedo;
	float depth;
};

struct PipelineInput {
	vec2 uv;
	vec4 vert_color;
	vec4 fragcoord;
};

PipelineOutput pipeline_transparent(PipelineInput input, sampler2D screen_tex, vec2 screen_uv) {
	vec2 uv = input.uv / clip_pos.w;
	PipelineOutput output;
	output.albedo = get_albedo(input.vert_color, textures[tex_id], uv);
	if (fog_kind == FOG_SH) {
		output.albedo = get_fog_color(output.albedo, fog_factor);
	}
	output.albedo = apply_semi_transparency(output.albedo, screen_tex, screen_uv);
	output.albedo = dither(output.albedo, input.fragcoord.xy);
	output.albedo = to_rgb5(output.albedo);
	output.albedo = to_linear(output.albedo);

	output.depth = depth;
	
	return output;
}

PipelineOutput pipeline_opaque(PipelineInput input) {
	vec2 uv = input.uv / clip_pos.w;
	PipelineOutput output;
	output.albedo = get_albedo(input.vert_color, textures[tex_id], uv);
	if (fog_kind == FOG_SH) {
		output.albedo = get_fog_color(output.albedo, fog_factor / clip_pos.w);
	}
	output.albedo = dither(output.albedo, input.fragcoord.xy);
	output.albedo = to_rgb5(output.albedo);
	output.albedo = to_linear(output.albedo);
	
	output.depth = depth;
	
	return output;
}

#define APPLY(o)\
	ALBEDO = o.albedo;\
	DEPTH = o.depth;
