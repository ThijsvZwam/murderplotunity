Shader "Custom/MSVO"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthTex ("Depth Texture", 2D) = "white" {}
        _AORadius ("AO Radius", Range(0.1, 5.0)) = 1.0
        _AOIntensity ("AO Intensity", Range(0, 2)) = 1.0
        _AOSamples ("AO Samples", Int) = 16
        _AOScale1 ("AO Scale 1", Float) = 1.0
        _AOScale2 ("AO Scale 2", Float) = 0.5
        _AOScale3 ("AO Scale 3", Float) = 0.25
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
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
            sampler2D _DepthTex;
            float _AORadius;
            float _AOIntensity;
            int _AOSamples;
            float _AOScale1;
            float _AOScale2;
            float _AOScale3;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, v2f o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float3 getWorldPosition(float2 uv, float depth)
            {
                // Reconstruct world position from depth
                float4 clipPos = float4(uv * 2.0 - 1.0, depth, 1.0);
                float4 worldPos = mul(unity_CameraToWorld, mul(unity_CameraInvProjection, clipPos));
                return worldPos.xyz / worldPos.w;
            }

            float calculateAO(float2 uv, float3 worldPos, float3 normal, float radius, float scale)
            {
                float ao = 0.0;
                float3 randomVec = normalize(float3(rand(uv), rand(uv + 0.5), 0.0));

                for (int i = 0; i < _AOSamples; i++)
                {
                    float3 sampleDir = normalize(randomVec + float3(i, i * 0.5, i * 0.25));
                    float3 samplePos = worldPos + sampleDir * radius * scale;

                    // Project sample position to screen space
                    float4 sampleClipPos = mul(unity_CameraProjection, float4(samplePos, 1.0));
                    float2 sampleUV = (sampleClipPos.xy / sampleClipPos.w) * 0.5 + 0.5;

                    // Sample depth texture
                    float sampleDepth = tex2D(_DepthTex, sampleUV).r;
                    float3 sampleWorldPos = getWorldPosition(sampleUV, sampleDepth);

                    // Calculate obscurance
                    float3 diff = sampleWorldPos - worldPos;
                    float dist = length(diff);
                    float rangeCheck = smoothstep(0.0, radius, dist);
                    ao += max(0.0, dot(normal, diff) - 0.1) * rangeCheck;
                }

                ao /= _AOSamples;
                return ao;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

                // Sample depth texture
                float depth = tex2D(_DepthTex, i.uv).r;

                // Reconstruct world position
                float3 worldPos = getWorldPosition(i.uv, depth);

                // Calculate normals (approximate from depth)
                float2 texelSize = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
                float depthX = tex2D(_DepthTex, i.uv + float2(texelSize.x, 0.0)).r;
                float depthY = tex2D(_DepthTex, i.uv + float2(0.0, texelSize.y)).r;
                float3 worldPosX = getWorldPosition(i.uv + float2(texelSize.x, 0.0), depthX);
                float3 worldPosY = getWorldPosition(i.uv + float2(0.0, texelSize.y), depthY);
                float3 normal = normalize(cross(worldPosX - worldPos, worldPosY - worldPos));

                // Calculate AO at multiple scales
                float ao1 = calculateAO(i.uv, worldPos, normal, _AORadius, _AOScale1);
                float ao2 = calculateAO(i.uv, worldPos, normal, _AORadius, _AOScale2);
                float ao3 = calculateAO(i.uv, worldPos, normal, _AORadius, _AOScale3);

                // Combine AO values
                float ao = (ao1 + ao2 + ao3) / 3.0;
                ao = saturate(1.0 - ao * _AOIntensity);

                // Sample the main texture
                float4 col = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, UnityStereoTransformScreenSpaceTex(i.uv));

                // Apply AO to the color
                col.rgb *= ao;

                return col;
            }
            ENDCG
        }
    }
}