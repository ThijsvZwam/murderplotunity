Shader "Custom/Vignette"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _VignetteColor ("Vignette Color", Color) = (0, 0, 0, 1)
        _VignetteIntensity ("Vignette Intensity", Range(0, 1)) = 0.5
        _VignetteSmoothness ("Vignette Smoothness", Range(0, 1)) = 0.5
        _VignetteRadius ("Vignette Radius", Range(0, 1)) = 0.75
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
            float4 _VignetteColor;
            float _VignetteIntensity;
            float _VignetteSmoothness;
            float _VignetteRadius;

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

                // Get the screen color
                float4 screenCol = getScreenCol(i.uv);

                // Calculate the distance from the center of the screen
                float2 center = float2(0.5, 0.5);
                float dist = distance(i.uv, center);

                // Calculate the vignette effect
                float vignette = smoothstep(_VignetteRadius, _VignetteRadius - _VignetteSmoothness, dist);
                vignette = lerp(1.0, vignette, _VignetteIntensity);

                // Apply the vignette effect to the screen color
                float4 finalColor = lerp(screenCol, _VignetteColor, 1.0 - vignette);

                return finalColor;
            }
            ENDCG
        }
    }
}