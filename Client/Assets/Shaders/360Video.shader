Shader "Universal Render Pipeline/360 Video"
{
    Properties
    {
        _MainTex ("Video Texture", 2D) = "white" {}
        _Layout ("Layout Type", Float) = 0 // 0: Equirectangular, 1: Top-Bottom Stereo, 2: Side-by-Side Stereo
    }

    SubShader
    {
        Tags { "RenderType"="Skybox" "Queue"="Background" }
        LOD 200

        // Отображаем внутреннюю сторону сферы
        Cull Front

        Pass
        {
            Name "Unlit"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _Layout;

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Преобразование из объекта в клип-пространство
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // Преобразуем позицию на сфере в сферические координаты
                float3 sphereCoord = normalize(IN.positionOS.xyz); // Нормализуем координаты для сферы
                float theta = atan2(sphereCoord.z, sphereCoord.x); // Получаем угол для азимута
                float phi = acos(sphereCoord.y); // Получаем угол для склонения

                // Преобразуем сферические координаты в UV
                OUT.uv.x = (theta + 3.14159) / (2 * 3.14159); // 0..1 для оси X (от -π до π)
                OUT.uv.y = phi / 3.14159; // 0..1 для оси Y (от 0 до π)

                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv;

                // Инвертируем UV по X, так как мы внутри сферы
                uv.x = 1.0 - uv.x;

                if (_Layout == 0.0) // Equirectangular (Mono)
                {
                    // Для эквидистантной развертки изменений не требуется
                    // Инвертировать Y, если видео перевёрнуто
                    // uv.y = 1.0 - uv.y;
                }
                else if (_Layout == 1.0) // Top-Bottom Stereo
                {
                    // Для Top-Bottom нужно поделить UV по вертикали
                    uv.y = uv.y * 0.5;
                    // TODO: Добавим переключение для глаз
                }
                else if (_Layout == 2.0) // Side-by-Side Stereo
                {
                    // Для Side-by-Side нужно поделить UV по горизонтали
                    uv.x = uv.x * 0.5;
                    // TODO: Добавим переключение для глаз
                }

                return tex2D(_MainTex, uv);
            }
            ENDHLSL
        }
    }
}
