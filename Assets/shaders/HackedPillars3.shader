Shader "Custom/HackedPillars3"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ScrollSpeed ("Scroll Speed", Float) = 1.0
        _CharacterDensity ("Character Density", Float) = 10.0
        _CharacterSize ("Character Size", Float) = 0.1
        _TextureColor ("Texture Color", Color) = (1, 1, 1, 1) // Color to tint the texture
        _CharacterColor ("Character Color", Color) = (0, 1, 0, 1) // Color of the falling characters
    }
    SubShader
    {
        Tags {
            "RenderType"="Opaque"
        }

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

            // Function to simulate characters and numbers
            float getCharacter(float2 uv, float seed)
            {
                // Create a grid for characters
                float2 grid = floor(uv);
                float2 cellUV = frac(uv);

                // Randomly select a character based on the seed
                float charIndex = floor(rand(grid + seed) * 10.0); // 0-9 for numbers

                // Define a simple 4x4 font for numbers
                float character = 0.0;
                if (charIndex == 0.0) character = cellUV.x > 0.2 && cellUV.x < 0.8 && cellUV.y > 0.2 && cellUV.y < 0.8 ? 1.0 : 0.0; // 0
                else if (charIndex == 1.0) character = cellUV.x > 0.4 && cellUV.x < 0.6 ? 1.0 : 0.0; // 1
                else if (charIndex == 2.0) character = cellUV.y < 0.2 || cellUV.y > 0.8 || (cellUV.x > 0.8 && cellUV.y < 0.5) || (cellUV.x < 0.2 && cellUV.y > 0.5) ? 1.0 : 0.0; // 2
                else if (charIndex == 3.0) character = cellUV.y < 0.2 || cellUV.y > 0.8 || (cellUV.x > 0.8 && cellUV.y < 0.5) || (cellUV.x > 0.8 && cellUV.y > 0.5) ? 1.0 : 0.0; // 3
                else if (charIndex == 4.0) character = cellUV.x < 0.2 || cellUV.y > 0.5 || (cellUV.x > 0.8 && cellUV.y < 0.5) ? 1.0 : 0.0; // 4
                else if (charIndex == 5.0) character = cellUV.y < 0.2 || cellUV.y > 0.8 || (cellUV.x < 0.2 && cellUV.y < 0.5) || (cellUV.x > 0.8 && cellUV.y > 0.5) ? 1.0 : 0.0; // 5
                else if (charIndex == 6.0) character = cellUV.y < 0.2 || cellUV.y > 0.8 || (cellUV.x < 0.2 && cellUV.y < 0.5) || (cellUV.x > 0.8 && cellUV.y > 0.5) || (cellUV.x < 0.2 && cellUV.y > 0.5) ? 1.0 : 0.0; // 6
                else if (charIndex == 7.0) character = cellUV.y < 0.2 || (cellUV.x > 0.8 && cellUV.y < 0.5) ? 1.0 : 0.0; // 7
                else if (charIndex == 8.0) character = cellUV.y < 0.2 || cellUV.y > 0.8 || cellUV.x < 0.2 || cellUV.x > 0.8 ? 1.0 : 0.0; // 8
                else if (charIndex == 9.0) character = cellUV.y < 0.2 || cellUV.y > 0.8 || cellUV.x < 0.2 || (cellUV.x > 0.8 && cellUV.y < 0.5) ? 1.0 : 0.0; // 9

                return character;
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
            float _ScrollSpeed;
            float _CharacterDensity;
            float _CharacterSize;
            float4 _TextureColor;
            float4 _CharacterColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // Sample the main texture and apply the tint color
                fixed4 texCol = tex2D(_MainTex, i.uv) * _TextureColor;

                // Create scrolling effect for characters
                float2 scrollUV = i.uv * float2(1.0, _CharacterDensity); // Scale Y for density
                scrollUV.y += _Time.y * _ScrollSpeed; // Scroll downwards

                // Get a random character
                float character = getCharacter(scrollUV, floor(_Time.y * 10.0)); // Change seed over time

                // Blend the character with the texture
                fixed4 finalCol = lerp(texCol, _CharacterColor, character);

                return finalCol;
            }
            ENDCG
        }
    }
}