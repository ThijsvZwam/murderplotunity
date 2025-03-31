Shader "Custom/TvDist"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _VertJerk ("Vertical Jerk", Float) = 1
        _VertMovement ("Vertical Movement", Float) = 1
        _BottomStatic ("Bottom Static", Float) = 1
        _Scanlines ("Scanlines", Float) = 1
        _RGBOffset ("RGB Offset", Float) = 1
        _HorzFuzz ("Horizontal Fuzz", Float) = 1
        _Intensity ("Effect Intensity", Range(0, 1)) = 1
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

            // VivifyTemplate Libraries
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_NoiseTex);
            float _VertJerk;
            float _VertMovement;
            float _BottomStatic;
            float _Scanlines;
            float _RGBOffset;
            float _HorzFuzz;
            float _Intensity;

            // Noise functions
            float3 mod289(float3 x) {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }

            float2 mod289(float2 x) {
                return x - floor(x * (1.0 / 289.0)) * 289.0;
            }

            float3 permute(float3 x) {
                return mod289(((x*34.0)+1.0)*x);
            }

            float snoise(float2 v)
            {
                const float4 C = float4(0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439);
                float2 i = floor(v + dot(v, C.yy));
                float2 x0 = v - i + dot(i, C.xx);
                float2 i1 = (x0.x > x0.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
                float4 x12 = x0.xyxy + C.xxzz;
                x12.xy -= i1;
                i = mod289(i);
                float3 p = permute(permute(i.y + float3(0.0, i1.y, 1.0)) + i.x + float3(0.0, i1.x, 1.0));
                float3 m = max(0.5 - float3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
                m = m*m;
                m = m*m;
                float3 x = 2.0 * frac(p * C.www) - 1.0;
                float3 h = abs(x) - 0.5;
                float3 ox = floor(x + 0.5);
                float3 a0 = x - ox;
                m *= 1.79284291400159 - 0.85373472095314 * (a0*a0 + h*h);
                float3 g;
                g.x = a0.x * x0.x + h.x * x0.y;
                g.yz = a0.yz * x12.xz + h.yz * x12.yw;
                return 130.0 * dot(m, g);
            }

            float staticV(float2 uv) {
                float time = _Time.y;
                float staticHeight = snoise(float2(9.0,time*1.2+3.0))*0.3+5.0;
                float staticAmount = snoise(float2(1.0,time*1.2-6.0))*0.1+0.3;
                float staticStrength = snoise(float2(-9.75,time*0.6-3.0))*2.0+2.0;
                return (1.0-step(snoise(float2(5.0*pow(time,2.0)+pow(uv.x*7.0,1.2),pow((fmod(time,100.0)+100.0)*uv.y*0.3+3.0,staticHeight))),staticAmount))*staticStrength;
            }

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 getScreenCol(float2 uv)
            {
                return UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoTransformScreenSpaceTex(uv));
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                float time = _Time.y;
                float2 uv = i.uv;
                
                // Original color
                float4 original = getScreenCol(uv);
                
                // Vertical effects
                float jerkOffset = (1.0-step(snoise(float2(time*1.3,5.0)),0.8))*0.05 * _VertJerk;
                float fuzzOffset = snoise(float2(time*15.0,uv.y*80.0))*0.003 * _HorzFuzz;
                float largeFuzzOffset = snoise(float2(time*1.0,uv.y*25.0))*0.004 * _HorzFuzz;
                float vertMovementOn = (1.0-step(snoise(float2(time*0.2,8.0)),0.4))*_VertMovement;
                float vertJerk = (1.0-step(snoise(float2(time*1.5,5.0)),0.6))*_VertJerk;
                float vertJerk2 = (1.0-step(snoise(float2(time*5.5,5.0)),0.2))*_VertJerk;
                float yOffset = abs(sin(time)*4.0)*vertMovementOn+vertJerk*vertJerk2*0.3;
                float y = fmod(uv.y+yOffset,1.0);
                
                // Horizontal effects
                float xOffset = (fuzzOffset + largeFuzzOffset) * _HorzFuzz;
                
                // Static noise
                float staticVal = 0.0;
                if (_BottomStatic > 0.5) {
                    for (float yDist = -1.0; yDist <= 1.0; yDist += 1.0) {
                        float maxDist = 5.0/200.0;
                        float dist = yDist/200.0;
                        staticVal += staticV(float2(uv.x,uv.y+dist))*(maxDist-abs(dist))*1.5;
                    }
                }
                
                // RGB offset sampling
                float red = getScreenCol(float2(uv.x + xOffset -0.01*_RGBOffset,y)).r + staticVal;
                float green = getScreenCol(float2(uv.x + xOffset,y)).g + staticVal;
                float blue = getScreenCol(float2(uv.x + xOffset +0.01*_RGBOffset,y)).b + staticVal;
                
                float3 color = float3(red,green,blue);
                
                // Scanlines
                if (_Scanlines > 0.5) {
                    float scanline = sin(uv.y*800.0)*0.04;
                    color -= scanline;
                }
                
                // Apply effect intensity
                float4 effect = float4(color, original.a);
                return lerp(original, effect, _Intensity);
            }
            ENDCG
        }
    }
}