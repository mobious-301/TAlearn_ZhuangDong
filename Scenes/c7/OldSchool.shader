Shader "AP01/L07/3ColAmbient" {
    Properties {
        _MainCol ("MainCol", color) = (1,1,1)
        _LightCol ("LightCol", Color) = (1,1,1,1)
        _EnvUpCol ("_EnvUpCol", color) = (1,1,1)
        _EnvSideCol ("_EnvSideCol", color) = (1,1,1)
        _EnvDownCol ("_EnvDownCol", color) = (1,1,1)
        _SpeacularPow("高光次幂",range(1,90)) = 30
        _Occlosion ("ao", 2d) = "white" {}
    }
    SubShader {
        Tags {
            "RenderType"="Opaque"
        }
        Pass {
            Name "FORWARD"
            // Tags {
            //     "LightMode"="ForwardBase"
            // } //被urp 抛弃


            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma multi_compile_fwdbase_fullshadows
            #pragma target 3.0

            float3 _MainCol;
            float3 _LightCol;
            float3 _EnvUpCol;
            float3 _EnvSideCol;
            float3 _EnvDownCol;
            float _SpeacularPow;
            sampler _Occlosion;
            // 输入结构
            struct VertexInput {
                float4 vertex : POSITION;   // 将模型顶点信息输入进来
                float4 normal : NORMAL;     // 将模型法线信息输入进来
                float3 uv : TEXCOORD0;  // 由模型法线信息换算来的世界空间法线信息
            };
            // 输出结构
            struct VertexOutput {
                float4 posCS : SV_POSITION;   // 由模型顶点信息换算而来的顶点屏幕位置
                float4 posWS : TEXCOORD0;   // 由模型顶点信息换算而来的顶点屏幕位置
                float3 nDirWS : TEXCOORD1;  // 由模型法线信息换算来的世界空间法线信息
                float3 uv : TEXCOORD2;  // 由模型法线信息换算来的世界空间法线信息
            };
            // 输入结构>>>顶点Shader>>>输出结构
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;               // 新建一个输出结构
                o.posCS = UnityObjectToClipPos( v.vertex );       // 变换顶点信息 并将其塞给输出结构
                o.posWS = mul(unity_ObjectToWorld,v.vertex);
                o.nDirWS = UnityObjectToWorldNormal(v.normal);  // 变换法线信息 并将其塞给输出结构
                o.uv=v.uv;
                return o;                                       // 将输出结构 输出
            }
            // 输出结构>>>像素
            float4 frag(VertexOutput i) : COLOR {
                //准备向量
                float3 nDir = i.nDirWS;                         // 获取nDir
                float3 lDir = _WorldSpaceLightPos0.xyz;         // 获取lDir
                float3 vDir = normalize(_WorldSpaceCameraPos.xyz-i.posWS);
                float3 hDir = normalize(vDir+lDir);

                //准备点积结果
                float nDotl = dot(i.nDirWS, lDir);              // nDir点积lDir
                float nDoth = dot(i.nDirWS, hDir);
                    //环境光遮罩
                float upMask = max(0.0, i.nDirWS.y);
                float downMask = max(0.0, 0-i.nDirWS.y);
                float sideMask = max(0.0, 1-upMask-downMask);
                float3 envCol = _EnvUpCol*upMask+_EnvSideCol*sideMask+_EnvDownCol*downMask;
                float occlosion = tex2D(_Occlosion,i.uv);

                

                //光照模型
                // float halflambert = nDotl*0.5+0.5;
                // float blinphong = pow(max(0.0, nDoth), _SpeacularPow);                // 截断负值
                // float3 finalRGB = _MainCol * halflambert + blinphong;
                //光照模型
                float3 finalRGB = envCol * occlosion;
                return float4(finalRGB.xyz, 1.0);  // 输出最终颜色
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}