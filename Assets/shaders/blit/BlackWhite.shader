Shader "Custom/BlackWhite"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Intensity ("Black & White Intensity", Range(0, 1)) = 1.0
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
            float _Intensity;

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

                // Get the original color from the texture
                float4 originalColor = getScreenCol(i.uv);

                // Convert the color to grayscale using luminance
                float luminance = dot(originalColor.rgb, float3(0.2126, 0.7152, 0.0722));
                float4 grayscaleColor = float4(luminance, luminance, luminance, originalColor.a);

                // Blend between the original color and grayscale based on intensity
                float4 finalColor = lerp(originalColor, grayscaleColor, _Intensity);

                return finalColor;
            }
            ENDCG
        }
    }
}