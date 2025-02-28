Shader "Custom/blackholesuck"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DistortionStrength ("Distortion Strength", Float) = 1.0
        _BlackHoleRadius ("Black Hole Radius", Float) = 0.1
        _BlackHolePosition ("Black Hole Position", Vector) = (0.5, 0.5, 0, 0)
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
            float _DistortionStrength;
            float _BlackHoleRadius;
            float2 _BlackHolePosition;

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

                // Calculate the direction and distance to the black hole
                float2 dir = i.uv - _BlackHolePosition;
                float distance = length(dir);
                float2 normalizedDir = normalize(dir);

                // Calculate the distortion factor
                float distortion = _DistortionStrength * (_BlackHoleRadius / distance);

                // Apply the distortion to the UV coordinates
                float2 distortedUV = i.uv + normalizedDir * distortion;

                // Sample the screen texture with the distorted UV coordinates
                fixed4 col = getScreenCol(distortedUV);

                return col;
            }
            ENDCG
        }
    }
}