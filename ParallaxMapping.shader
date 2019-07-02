Shader "Custom/ParallaxMapping"
{
    Properties
    {
		_Diffuse("Diffuse",Color) = (1,1,1,1)
		_MainTex("Main Tex",2D)="White"{}
		_Specular("Specular",Color) = (1,1,1,1)
		_Gloss("Gloss",Range(8.0,256)) = 20
		_Color("Color Tint",Color) = (1,1,1,1)
		_BumpMap("Normal Map",2D)="bump"{}
		_BumpScale("Bump Scale",Float)=1.0
		//**********************************
		_HeightMap("_DepthMap",2D)="white"{}
		_HeightScale("HeightScale",Range(0.005,0.08)) = 1
		//*******************************
    }
		SubShader{
		pass {
		Tags{"LightMode" = "ForwardBase"}

			CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#include"Lighting.cginc"
		fixed4 _Diffuse;
		sampler2D _MainTex;
		fixed4 _MainTex_ST;
		sampler2D _BumpMap;
		fixed4 _BumpMap_ST;
		float _BumpScale;
		fixed4 _Specular;
		float _Gloss;
		fixed4 _Color;
		//*********************
		sampler2D _DepthMap;
		float _HeightScale;
		//***********************
		struct a2f {
			float4 vertex:POSITION;
			float3 normal:NORMAL;
			float4 texcoord:TEXCOORD0;
			float4 tangent:TANGENT;
		};
		struct v2f {
			float4 pos:SV_POSITION;
			float4 uv:TEXCOORD0;
			float4 TtoW0:TEXCOORD1;
			float4 TtoW1:TEXCOORD2;
			float4 TtoW2:TEXCOORD3;
		};
		v2f vert(a2f v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv.xy = v.texcoord.xy*_MainTex_ST.xy + _MainTex_ST.zw;
			o.uv.zw = v.texcoord.xy*_BumpMap_ST.xy + _BumpMap_ST.zw;

			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
			fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
			fixed3 worldBinormal = cross(worldNormal, worldTangent)*v.tangent.w;

			o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
			o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
			o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
			return o;
		}
		fixed4 frag(v2f i) :SV_Target{
			float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
			
			fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
			fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			//**************************************
			float height = tex2D(_DepthMap, i.uv.zw);
			float2 p = viewDir.xy / viewDir.z * (height * _HeightScale);
			i.uv.zw = i.uv.zw - p;
			//**************************************
			fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
			bump.xy *= _BumpScale;
			bump.z = sqrt(1 - saturate(dot(bump.xy, bump.xy)));
			bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

			fixed3 albedo = tex2D(_MainTex, i.uv).rgb*_Color.rgb;
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;

			fixed3 diffuse = _LightColor0.rgb*_Diffuse.rbg*albedo*max(dot(bump, lightDir),0);
			
			fixed3 halfDir = normalize(lightDir + lightDir);			
			fixed3 specular = _LightColor0.rgb*_Specular.rgb*pow(max(0,dot(bump, halfDir)), _Gloss);
			
			
			return fixed4(diffuse + ambient+ specular, 1.0);
		}
			ENDCG

		}
	}
    FallBack "Specular"
}
