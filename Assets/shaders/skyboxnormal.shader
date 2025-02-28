Shader "Custom/skyboxnormal"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color1 ("Top Color", Color) = (1,1,1,0)
        _Color2 ("Horizon Color", Color) = (1,1,1,0)
        _Color3 ("Bottom Color", Color) = (1,1,1,0)
        _Exp1 ("Top Half", Float) = 1.0
        _Exp2 ("Bottom Half", Float) = 1.0
        _Intensity ("Intensity", Float) = 1.0
        _Angle ("Angle", Float) = 0.0

    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

        Cull Front
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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            half4 _Color1;
            half4 _Color2;
            half4 _Color3;
            half _Intensity;
            half _Exp1;
            half _Exp2;
            half _Angle;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                
                float2 uv = i.uv * 1.0 - 1.0;
                float radial = length(uv);

                radial = saturate(radial + _Angle);

                if (radial < 0.5)
                {
                    col = lerp(_Color1, _Color2, radial * 2.0);
                }
                else
                {
                    col = lerp(_Color2, _Color3, (radial - 0.5) * 2.0);
                }

                col *= _Intensity;

                return col;
            }
            ENDCG
        }
    }
}
