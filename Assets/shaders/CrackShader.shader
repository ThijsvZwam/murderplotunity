Shader "Custom/CrackShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DarkColor ("Dark Color", Color) = (0, 0, 0, 1) // Blackish areas
        _LightColor ("Light Color", Color) = (1, 0, 1, 1) // Purple glow for cracks
        _OffsetIntensity ("Offset Intensity", Float) = 0.01 // Controls the intensity of the random offset
        _OffsetSpeed ("Offset Speed", Float) = 1.0 // Controls how fast the offset changes
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            // Simple noise function for randomness
            float rand(float2 co)
            {
                return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _DarkColor;
            float4 _LightColor;
            float _OffsetIntensity;
            float _OffsetSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Generate random offsets for x and y based on time
                float2 randomOffset = float2(
                    rand(float2(_Time.y * _OffsetSpeed, 0.0)) * 2.0 - 1.0, // Random x offset (-1 to 1)
                    rand(float2(0.0, _Time.y * _OffsetSpeed)) * 2.0 - 1.0  // Random y offset (-1 to 1)
                ) * _OffsetIntensity; // Scale by intensity

                // Apply the random offset to the UV coordinates
                float2 offsetNow = i.uv;
                float2 offsetUV = offsetNow - (i.uv + randomOffset);
                
                // Sample the texture with the offset UVs
                fixed4 col = tex2D(_MainTex, offsetUV);

                // Extract brightness from the texture (luminance)
                float brightness = dot(col.rgb, float3(0.3, 0.59, 0.11)); 

                // Interpolate between DarkColor (blackish) and LightColor (purple) based on brightness
                float4 finalColor = lerp(_DarkColor, _LightColor, brightness);

                return finalColor;
            }
            ENDCG
        }
    }
}