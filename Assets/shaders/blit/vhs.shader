Shader "Custom/VHS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        _ScanlineIntensity ("Scanline Intensity", Float) = 1
        _DistortionAmount ("Distortion Amount", Float) = 0.005
        _NoiseIntensity ("Noise Intensity", Float) = 0
        _ChromaticAberration ("Chromatic Aberration", Float) = 0.005
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
            UNITY_DECLARE_SCREENSPACE_TEXTURE(_NoiseTex);
            float _ScanlineIntensity;
            float _DistortionAmount;
            float _NoiseIntensity;
            float _ChromaticAberration;

            v2f vert (appdata v)
            {
                UNITY_SETUP_INSTANCE_ID(v);
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
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

                float4 originalColor = getScreenCol(i.uv);

                // Chromatic Aberration
                float2 uvRed = i.uv + float2(-_ChromaticAberration, 0);
                float2 uvBlue = i.uv + float2(_ChromaticAberration, 0);
                float4 colRed = getScreenCol(uvRed);
                float4 colGreen = getScreenCol(i.uv);
                float4 colBlue = getScreenCol(uvBlue);
                
                float4 color = float4(colRed.r, colGreen.g, colBlue.b, 1.0);

                // Scanlines
                float scanline = sin(i.uv.y * 800.0 + _Time.y * 10.0) * _ScanlineIntensity;
                color.rgb *= 1.0 - scanline;

                // Noise
                float noise = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_NoiseTex, i.uv * 10.0 + _Time.yy * 10.0).r;
                color.rgb += (noise - 0.5) * _NoiseIntensity;

                // Distortion
                float2 distortion = float2(sin(i.uv.y * 20.0 + _Time.y * 5.0), 0) * _DistortionAmount;
                float4 distortedColor = getScreenCol(i.uv + distortion);
                
                return lerp(originalColor, color, 0.5) + (distortedColor - originalColor) * 0.5;
            }
            ENDCG
        }
    }
}
