Shader "Unlit/OldSchoolPro"
{

    Properties

    {

        // _MainTex("MainTex",2D)="white"{}

        // _BaseColor("BaseColor",Color)=(1,1,1,1)

        // _Gloss("gloss",Range(10,300))=20

        // _SpecularColor("SpecularColor",Color  )=(1,1,1,1)

        [Header(Texture)]
            _MainTex    ("RGB:基础颜色 A:环境遮罩", 2D)     = "white" {}
            _NormTex	("RGB:法线贴图", 2D)                = "bump" {}
            _SpecTex    ("RGB:高光颜色 A:高光次幂", 2D)     = "gray" {}
            _EmitTex    ("RGB:环境贴图", 2d)                = "black" {}
            _Cubemap    ("RGB:环境贴图", cube)              = "_Skybox" {}
        [Header(Diffuse)]
            _MainCol    ("基本色",      Color)              = (0.5, 0.5, 0.5, 1.0)
            _EnvDiffInt ("环境漫反射强度",  Range(0, 1))    = 0.2
            _EnvUpCol   ("环境天顶颜色", Color)             = (1.0, 1.0, 1.0, 1.0)
            _EnvSideCol ("环境水平颜色", Color)             = (0.5, 0.5, 0.5, 1.0)
            _EnvDownCol ("环境地表颜色", Color)             = (0.0, 0.0, 0.0, 0.0)
        [Header(Specular)]
            _SpecPow    ("高光次幂",    Range(1, 90))       = 30
            _EnvSpecInt ("环境镜面反射强度", Range(0, 5))   = 0.2
            _FresnelPow ("菲涅尔次幂", Range(0, 5))         = 1
            _CubemapMip ("环境球Mip", Range(0, 7))          = 0
        [Header(Emission)]
            _EmitInt    ("自发光强度", range(1, 10))         = 1

    }

    SubShader

    {

        Tags{

        "RenderPipeline"="UniversalRenderPipeline"

        "RenderType"="Opaque"

        }

        HLSLINCLUDE

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



        CBUFFER_START(UnityPerMaterial)

        float4 _MainTex_ST;

        half4 _BaseColor;

        half _Gloss;

        real4 _SpecularColor;

        CBUFFER_END

        // TEXTURE2D( _MainTex);

        SAMPLER(sampler_MainTex);

         struct a2v

         {

             float4 vertex:POSITION;

             float4 normal:NORMAL;

             float2 uv0:TEXCOORD;

             float4 tangent  : TANGENT;    // 切线信息 Get✔

         };

         struct v2f

         {

             float4 pos : SV_POSITION;

             float2 uv0 : TEXCOORD;

             float3 posWS:TEXCOORD1; 

             float2 uv1 : TEXCOORD5;

             float3 normalWS:NORMAL;

             float3 nDirWS   : TEXCOORD2;  // 世界空间法线方向
             float3 tDirWS   : TEXCOORD3;  // 世界空间切线方向
             float3 bDirWS   : TEXCOORD4;  // 世界空间副切线方向

         };

        ENDHLSL


        pass

        {

            Tags{

            "LightMode"="UniversalForward"

            }

            HLSLPROGRAM

            #pragma vertex VERT

            #pragma fragment FRAG

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

            // 输入参数
            // Texture
            uniform sampler2D _MainTex;
            uniform sampler2D _NormTex;
            uniform sampler2D _SpecTex;
            uniform sampler2D _EmitTex;
            uniform samplerCUBE _Cubemap;
            // Diffuse
            uniform float3 _MainCol;
            uniform float _EnvDiffInt;
            uniform float3 _EnvUpCol;
            uniform float3 _EnvSideCol;
            uniform float3 _EnvDownCol;
            // Specular
            uniform float _SpecPow;
            uniform float _FresnelPow;
            uniform float _EnvSpecInt;
            uniform float _CubemapMip;
            // Emission
            uniform float _EmitInt;


            v2f VERT(a2v v)

            {

                v2f o;

                o.normalWS=TransformObjectToWorldNormal(v.normal.xyz);

                o.pos = TransformObjectToHClip( v.vertex.xyz );       // 顶点位置 OS>CS
                o.uv0 = v.uv0;                                  // 传递UV
                o.uv1 = v.uv0;
                // o.posWS = mul(unity_ObjectToWorld, v.vertex);   // 顶点位置 OS>WS
                o.posWS = TransformObjectToWorld(v.vertex.xyz);
                o.nDirWS = TransformObjectToWorldNormal(v.normal.xyz);  // 法线方向 OS>WS
                o.tDirWS = normalize(mul(unity_ObjectToWorld, float4(v.tangent.xyz, 0.0)).xyz); // 切线方向 OS>WS
                o.bDirWS = normalize(cross(o.nDirWS, o.tDirWS) * v.tangent.w);  // 副切线方向
               

                return o;

            }

            half4 FRAG(v2f i):SV_TARGET

            {

                // 准备向量
                float3 nDirTS = UnpackNormal(tex2D(_NormTex, i.uv1)).rgb;
                float3x3 TBN = float3x3(i.tDirWS, i.bDirWS, i.nDirWS);
                float3 nDirWS = normalize(mul(nDirTS, TBN));
                float3 vDirWS = normalize(_WorldSpaceCameraPos.xyz - i.posWS.xyz);
                float3 vrDirWS = reflect(-vDirWS, nDirWS);
                float3 lDirWS = _MainLightPosition.xyz;
                float3 lrDirWS = reflect(-lDirWS, nDirWS);

                // 准备点积结果
                float ndotl = dot(nDirWS, lDirWS);
                float vdotr = dot(vDirWS, lrDirWS);
                float vdotn = dot(vDirWS, nDirWS);

                // 采样纹理
                float4 var_MainTex = tex2D(_MainTex, i.uv1);
                float4 var_SpecTex = tex2D(_SpecTex, i.uv1);
                float3 var_EmitTex = tex2D(_EmitTex, i.uv1).rgb;
                float3 var_Cubemap = texCUBElod(_Cubemap, float4(vrDirWS, lerp(_CubemapMip, 0.0, var_SpecTex.a))).rgb;

                Light mylight=GetMainLight(TransformWorldToShadowCoord(i.posWS));
                float shadow = mylight.shadowAttenuation;

                // 光照模型(直接光照部分)
                float3 baseCol = var_MainTex.rgb * _MainCol;
                float lambert = max(0.0, ndotl);

                float3 specCol = var_SpecTex.xyz;
                float specPow = lerp(1, _SpecPow, var_SpecTex.a);
                float phong = pow(max(0.0, vdotr), specPow);
                
                // float shadow = LIGHT_ATTENUATION(i);

                float3 dirLighting = (baseCol * lambert + specCol * phong) * _MainLightColor.xyz * shadow;

                // 光照模型(环境光照部分)
                float upMask = max(0.0, nDirWS.g);          // 获取朝上部分遮罩
                float downMask = max(0.0, -nDirWS.g);       // 获取朝下部分遮罩
                float sideMask = 1.0 - upMask - downMask;   // 获取侧面部分遮罩
                float3 envCol = _EnvUpCol * upMask +
                                _EnvSideCol * sideMask +
                                _EnvDownCol * downMask;     // 混合环境色

                float fresnel = pow(max(0.0, 1.0 - vdotn), _FresnelPow);    // 菲涅尔

                float occlusion = var_MainTex.a;

                float3 envLighting = (baseCol * envCol * _EnvDiffInt + var_Cubemap * fresnel * _EnvSpecInt * var_SpecTex.a) * occlusion;

                // 光照模型(自发光部分)
                float emitInt = _EmitInt * (sin(frac(_Time.z)) * 0.5 + 0.5);
                float3 emission = var_EmitTex * emitInt;

                // 返回结果
                float3 finalRGB = dirLighting + envLighting + emission;
                return float4(finalRGB.xyz, 1.0);
            }

            ENDHLSL

        }


        // pass

        // {

        // Tags{

        //  "LightMode"="UniversalForward"

        // }

        //     HLSLPROGRAM

        //     #pragma vertex VERT

        //     #pragma fragment FRAG

        //     #pragma multi_compile _ _MAIN_LIGHT_SHADOWS

        //     #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

        //     #pragma multi_compile _ _SHADOWS_SOFT//柔化阴影，得到软阴影

        //     v2f VERT(a2v i)

        //     {

        //         v2f o;

        //         o.positionCS=TransformObjectToHClip(v.positionOS.xyz);

        //         o.texcoord=TRANSFORM_TEX(v.texcoord,_MainTex);

        //         o.positionWS=TransformObjectToWorld(v.positionOS.xyz);

        //         o.normalWS=TransformObjectToWorldNormal(v.normal);

        //         return o;

        //     }

        //     half4 FRAG(v2f i):SV_TARGET

        //     {

        //         half4 tex=SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,v.texcoord)*_BaseColor;

        //         Light mylight=GetMainLight(TransformWorldToShadowCoord(v.positionWS));

        //         float3 WS_L=normalize(mylight.direction);

        //         float3 WS_N=normalize( v.normalWS);

        //         float3 WS_V=normalize(_WorldSpaceCameraPos-v.positionWS);

        //         float3 WS_H=normalize(WS_V+WS_L);

        //         tex*=(dot(WS_L,WS_N)*0.5+0.5)*mylight.shadowAttenuation*real4(mylight.color,1);

        //         float4 Specular =pow(max(dot(WS_N,WS_H),0) ,_Gloss)*_SpecularColor*mylight.shadowAttenuation;

        //         // return tex+Specular  ;
        //         return mylight.shadowAttenuation;
        //     }

        //     ENDHLSL
        // }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"



    }



        

} 
//作者：雪风carel https://www.bilibili.com/read/cv6436088/ 出处：bilibili