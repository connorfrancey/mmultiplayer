#pragma once

// Mirror's Edge (1.0) SDK

#pragma pack(push, 0x4)

namespace Classes
{
//---------------------------------------------------------------------------
//Classes
//---------------------------------------------------------------------------

// Class OnlineSubsystemPC.OnlineSubsystemPC
// 0x01B0 (0x025C - 0x00AC)
class UOnlineSubsystemPC : public UOnlineSubsystemCommonImpl
{
public:
	unsigned char                                      UnknownData00[0x1B0];                                     // 0x00AC(0x01B0) MISSED OFFSET

	static UClass* StaticClass()
	{
		static auto ptr = UObject::FindClass("Class OnlineSubsystemPC.OnlineSubsystemPC");
		return ptr;
	}

};


}

#pragma pack(pop)
