Shader "Custom/BlackHoleDemonCore"
{
    Properties
    {
        _Strength ("Strength", Float) = 1
        _FresnelPower ("Fresnel Power", Float) = 6
        _CoreThreshold ("Core Threshold", Float) = 0.9
        _Pulse ("Pulse", Range(0, 1)) = 0
        _GlitchIntensity ("Glitch Intensity", Range(0, 1)) = 0.5
        _DistortionStrength ("Distortion Strength", Float) = 0.1
        _ColorShiftSpeed ("Color Shift Speed", Float) = 1.0

        // Gradient properties
        _CoreGradient ("Core Gradient", 2D) = "white" {}
        _CoreGradientScale ("Core Gradient Scale", Float) = 1.0
        _CoreGradientOffset ("Core Gradient Offset", Float) = 0.0
        _CoreColor ("Core Color", Color) = (0, 0, 0, 1) // Default black
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        // ZTest Off

        GrabPass { "_GrabTexture1" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 screenUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD2;
                float3 normal : TEXCOORD3;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            float _Strength;
            float _FresnelPower;
            float _CoreThreshold;
            float _Pulse;
            float _GlitchIntensity;
            float _DistortionStrength;
            float _ColorShiftSpeed;

            sampler2D _CoreGradient;
            float _CoreGradientScale;
            float _CoreGradientOffset;
            fixed4 _CoreColor;

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_GrabTexture1);

            // Simple noise function for glitch effect
            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenUV = ComputeGrabScreenPos(o.vertex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.viewVector = normalize(worldPos - _WorldSpaceCameraPos);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            float2 worldToScreen(float3 pos) {
                float4 v = ComputeGrabScreenPos(UnityObjectToClipPos(pos));
                return v.xy / v.w;
            }

            float4 getGrabPassCol(float2 uv) {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_GrabTexture1, uv);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Screen to black hole center
                float2 centerUV = worldToScreen(float3(0,0,0));
                float2 screenUV = (i.screenUV) / i.screenUV.w;
                float2 toCenter = centerUV - screenUV;

                // Fresnel
                float d = dot(i.viewVector, i.normal);
                float fresnel = saturate(pow(1 - (-saturate(-d) * 0.5 + 0.5) * 3, _FresnelPower));

                // Distort
                float pulse = sin(_Time.y) * _Pulse;
                screenUV += toCenter * _Strength * fresnel * (1 + pulse * 0.5);
                float4 col = getGrabPassCol(screenUV);

                // Glitch effect using noise
                float glitch = rand(float2(_Time.y, i.uv.y)) * _GlitchIntensity;
                screenUV.x += glitch * _DistortionStrength;

                // Core gradient
                float gradientPos = saturate((d + _CoreGradientOffset) * _CoreGradientScale);
                fixed4 gradientColor = tex2D(_CoreGradient, float2(gradientPos, 0));

                // Core color blending
                fixed4 coreColor = lerp(_CoreColor, gradientColor, fresnel);

                // Core
                if (d < -_CoreThreshold + pulse * 0.01) {
                    return coreColor;
                }

                // Combine background distortion with glitch and gradient
                col.rgb = lerp(col.rgb, gradientColor.rgb, fresnel);
                col.rgb += glitch * 0.1;

                return col;
            }
            ENDCG
        }
    }
}