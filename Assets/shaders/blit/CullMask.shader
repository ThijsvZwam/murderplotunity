Shader "Custom/StencilMask"
{
    SubShader
    {
        Tags { "Queue"="Geometry+1" } // Render after regular geometry
        ColorMask 0 // Don't write to the color buffer
        ZWrite Off // Don't write to the depth buffer
        Stencil
        {
            Ref 1 // Reference value for the stencil buffer
            Comp Always // Always pass the stencil test
            Pass Replace // Replace the stencil buffer value with the reference value
        }

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
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // This shader doesn't output any color (ColorMask 0)
                return fixed4(0, 0, 0, 0);
            }
            ENDCG
        }
    }
}