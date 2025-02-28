Shader "Custom/GlitchThing"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GlitchIntensity ("Glitch Intensity", Range(0, 1)) = 0.1
        _ScanlineFrequency ("Scanline Frequency", Float) = 100.0
        _NoiseScale ("Noise Scale", Float) = 10.0
        _RGBSplitIntensity ("RGB Split Intensity", Float) = 0.02
    }
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // VivifyTemplate Libraries (uncomment if available)
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Colors.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Math.cginc"
            // #include "Assets/VivifyTemplate/Utilities/Shader Functions/Easings.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float4 screenUV : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
            float _GlitchIntensity;
            float _ScanlineFrequency;
            float _NoiseScale;
            float _RGBSplitIntensity;

            // Random function for noise
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
                o.screenUV = ComputeScreenPos(o.vertex);
                return o;
            }

            float4 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoTransformScreenSpaceTex(uv));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float2 uv = i.uv;
                float time = _Time.y;

                // RGB Split Effect
                float2 rgbOffset = float2(rand(float2(time, uv.y))) - 0.5, rand(float2(time, uv.x)) * _RGBSplitIntensity * _GlitchIntensity;
                float4 colR = getScreenCol(uv + rgbOffset * float2(1, 0));
                float4 colG = getScreenCol(uv);
                float4 colB = getScreenCol(uv - rgbOffset * float2(1, 0));

                // Combine RGB channels
                float4 rgbSplitCol = float4(colR.r, colG.g, colB.b, 1);

                // Scanline Effect
                float scanline = sin(uv.y * _ScanlineFrequency + time * 10.0) * 0.5 + 0.5;
                scanline = lerp(1.0, scanline, _GlitchIntensity);

                // Noise Effect
                float noise = rand(uv * _NoiseScale + float2(time, time));
                noise = lerp(1.0, noise, _GlitchIntensity);

                // Combine all effects
                float4 finalCol = rgbSplitCol * scanline * noise;

                return finalCol;
            }
            ENDCG
        }
    }
}