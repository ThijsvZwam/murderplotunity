Shader "Custom/RingEffect"
{
    Properties
    {
        _RingColorGradient ("Ring Color Gradient", 2D) = "white" {}
        _RingWidth ("Ring Width", Range(0, 1)) = 0.1
        _RingRadius ("Ring Radius", Range(0, 1)) = 0.5
        _RingSpeed ("Ring Speed", Float) = 1.0
    }
    SubShader
    {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off

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

            sampler2D _RingColorGradient;
            float _RingWidth;
            float _RingRadius;
            float _RingSpeed;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Calculate distance from the center
                float2 center = float2(0.5, 0.5);
                float dist = distance(i.uv, center);

                // Ring effect
                float ring = smoothstep(_RingRadius - _RingWidth, _RingRadius, dist) -
                             smoothstep(_RingRadius, _RingRadius + _RingWidth, dist);

                // Animate the ring radius over time
                float animatedRadius = _RingRadius + (sin(_Time.y * _RingSpeed) * 0.1);

                // Sample the color gradient based on time
                float gradientPos = (sin(_Time.y * _RingSpeed) * 0.5 + 0.5);
                fixed4 ringColor = tex2D(_RingColorGradient, float2(gradientPos, 0));

                // Combine ring effect with color gradient
                fixed4 col = ringColor * ring;

                // Make everything outside the ring transparent
                col.a = ring;

                return col;
            }
            ENDCG
        }
    }
}