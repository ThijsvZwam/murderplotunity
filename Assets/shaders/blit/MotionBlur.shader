Shader "Custom/MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MotionBlurDirection ("Motion Blur Direction", Vector) = (1, 0, 0, 0) // Direction of motion blur
        _MotionBlurLength ("Motion Blur Length", Float) = 1.0 // Intensity of motion blur
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
            float2 _MotionBlurDirection; // Direction of motion blur (normalized)
            float _MotionBlurLength;    // Length of motion blur

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

                float2 texelSize = float2(1.0 / _ScreenParams.x, 1.0 / _ScreenParams.y);
                float2 blurDirection = normalize(_MotionBlurDirection) * texelSize * _MotionBlurLength;

                // Sample the center pixel
                float4 color = getScreenCol(i.uv);

                // Sample along the motion blur direction
                int samples = 10; // Number of samples for motion blur
                for (int j = 1; j <= samples; j++)
                {
                    float2 offset = blurDirection * (float(j) / float(samples));
                    color += getScreenCol(i.uv + offset);
                }

                // Average the samples
                color /= (samples + 1);

                return color;
            }
            ENDCG
        }
    }
}