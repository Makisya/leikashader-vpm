    _NormalMap ("Normal Map", 2D) = "bump" {}
    _NormalStrength ("Normal Strength", Range(0, 2)) = 1

    [Toggle(_USE_EMISSION)] _UseEmission ("Use Emission", Float) = 1
    _EmissionMap1 ("Emission Map 1", 2D) = "black" {}
    _EmissionMap2 ("Emission Map 2", 2D) = "black" {}
    _EmissionMap3 ("Emission Map 3", 2D) = "black" {}
    _EmissionMap4 ("Emission Map 4", 2D) = "black" {}
    _EmissionMap5 ("Emission Map 5", 2D) = "black" {}
    _EmissionColor1 ("Emission Color 1", Color) = (0,0,0,1)
    _EmissionColor2 ("Emission Color 2", Color) = (0,0,0,1)
    _EmissionColor3 ("Emission Color 3", Color) = (0,0,0,1)
    _EmissionColor4 ("Emission Color 4", Color) = (0,0,0,1)
    _EmissionColor5 ("Emission Color 5", Color) = (0,0,0,1)
    _EmissionScroll1 ("Emission Scroll 1", Vector) = (0,0,0,0)
    _EmissionScroll2 ("Emission Scroll 2", Vector) = (0,0,0,0)
    _EmissionScroll3 ("Emission Scroll 3", Vector) = (0,0,0,0)
    _EmissionScroll4 ("Emission Scroll 4", Vector) = (0,0,0,0)
    _EmissionScroll5 ("Emission Scroll 5", Vector) = (0,0,0,0)

    _ShadeColor ("Shadow Color", Color) = (0.5,0.5,0.5,1)
    _ShadowStrength ("Shadow Strength", Range(0,1)) = 0.5

    [Toggle(_USE_MATCAP)] _UseMatcap ("Use Matcap", Float) = 1
    _MatcapTex ("Matcap Texture", 2D) = "gray" {}
    _MatcapStrength ("Matcap Strength", Range(0,1)) = 0.5

    [Toggle(_USE_REFLECTION)] _UseReflection ("Use Reflection", Float) = 1
    _ReflectionCube ("Reflection Cube", Cube) = "_Skybox" {}
    _ReflectionStrength ("Reflection Strength", Range(0,1)) = 0.2

    _DistanceShadeColor ("Distance Shade Color", Color) = (0,0,0,1)
    _DistanceStart ("Distance Start", Float) = 5.0
    _DistanceEnd ("Distance End", Float) = 20.0

    [Toggle(_USE_GLITTER)] _UseGlitter ("Use Glitter", Float) = 1
    _GlitterIntensity ("Glitter Intensity", Range(0,1)) = 0.2
    _GlitterScale ("Glitter Scale", Range(1,100)) = 10

    _ClipThreshold ("Clip Threshold", Range(0,1)) = 0.5
}

SubShader
{
    Tags { "RenderType" = "Opaque" }
    LOD 300

    CGPROGRAM
    #pragma surface surf Standard fullforwardshadows
    #pragma target 3.0

    #pragma shader_feature _USE_EMISSION
    #pragma shader_feature _USE_MATCAP
    #pragma shader_feature _USE_REFLECTION
    #pragma shader_feature _USE_GLITTER

    sampler2D _MainTex, _MainTex2, _MainTex3, _MainTex4, _MainTex5;
    sampler2D _NormalMap;
    sampler2D _EmissionMap1, _EmissionMap2, _EmissionMap3, _EmissionMap4, _EmissionMap5;
    sampler2D _MatcapTex;
    samplerCUBE _ReflectionCube;

    float _NormalStrength;
    fixed4 _Color;
    float _MainBlend;

    fixed4 _EmissionColor1, _EmissionColor2, _EmissionColor3, _EmissionColor4, _EmissionColor5;
    float4 _EmissionScroll1, _EmissionScroll2, _EmissionScroll3, _EmissionScroll4, _EmissionScroll5;

    fixed4 _ShadeColor;
    float _ShadowStrength;

    float _MatcapStrength;
    float _ReflectionStrength;

    fixed4 _DistanceShadeColor;
    float _DistanceStart, _DistanceEnd;

    float _GlitterIntensity, _GlitterScale;
    float _ClipThreshold;

    struct Input
    {
        float2 uv_MainTex;
        float2 uv_NormalMap;
        float2 uv_EmissionMap1;
        float3 worldPos;
        float3 viewDir;
        INTERNAL_DATA
    };

    void surf (Input IN, inout SurfaceOutputStandard o)
    {
        fixed4 tex1 = tex2D(_MainTex, IN.uv_MainTex);
        fixed4 tex2 = tex2D(_MainTex2, IN.uv_MainTex);
        fixed4 tex = lerp(tex1, tex2, _MainBlend);
        fixed4 c = tex * _Color;
        o.Albedo = c.rgb;
        o.Alpha = c.a;

        fixed3 normalTex = UnpackNormal(tex2D(_NormalMap, IN.uv_NormalMap));
        o.Normal = lerp(o.Normal, normalTex, _NormalStrength);

        #ifdef _USE_EMISSION
        float2 uv = IN.uv_MainTex;
        o.Emission = 
            tex2D(_EmissionMap1, uv + _Time.y * _EmissionScroll1.xy).rgb * _EmissionColor1.rgb +
            tex2D(_EmissionMap2, uv + _Time.y * _EmissionScroll2.xy).rgb * _EmissionColor2.rgb +
            tex2D(_EmissionMap3, uv + _Time.y * _EmissionScroll3.xy).rgb * _EmissionColor3.rgb +
            tex2D(_EmissionMap4, uv + _Time.y * _EmissionScroll4.xy).rgb * _EmissionColor4.rgb +
            tex2D(_EmissionMap5, uv + _Time.y * _EmissionScroll5.xy).rgb * _EmissionColor5.rgb;
        #endif

        o.Albedo = lerp(o.Albedo, _ShadeColor.rgb, _ShadowStrength);

        #ifdef _USE_MATCAP
        float3 viewN = normalize(UnityObjectToViewNormal(o.Normal));
        float2 capUV = viewN.xy * 0.5 + 0.5;
        fixed3 matcap = tex2D(_MatcapTex, capUV).rgb;
        o.Emission += matcap * _MatcapStrength;
        #endif

        #ifdef _USE_REFLECTION
        float3 refl = texCUBE(_ReflectionCube, reflect(-IN.viewDir, o.Normal)).rgb;
        o.Emission += refl * _ReflectionStrength;
        #endif

        float dist = distance(_WorldSpaceCameraPos, IN.worldPos);
        float distLerp = saturate((dist - _DistanceStart) / (_DistanceEnd - _DistanceStart));
        o.Albedo = lerp(o.Albedo, _DistanceShadeColor.rgb, distLerp);

        #ifdef _USE_GLITTER
        float glitter = frac(sin(dot(IN.worldPos.xyz ,float3(12.9898,78.233, 37.719))) * 43758.5453);
        glitter = step(1.0 - _GlitterIntensity, frac(glitter * _GlitterScale));
        o.Emission += glitter;
        #endif

        clip(o.Alpha - _ClipThreshold);
    }
    ENDCG
}

FallBack "Diffuse"