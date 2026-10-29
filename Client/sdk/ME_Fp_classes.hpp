#pragma once

// Mirror's Edge (1.0) SDK

#pragma pack(push, 0x4)

namespace Classes
{
//---------------------------------------------------------------------------
//Classes
//---------------------------------------------------------------------------

// Class Fp.FPSequence
// 0x000C (0x0048 - 0x003C)
class UFPSequence : public UObject
{
public:
	struct FString                                     Sequence;                                                 // 0x003C(0x000C) (NeedCtorLink)

	static UClass* StaticClass()
	{
		static auto ptr = UObject::FindClass("Class Fp.FPSequence");
		return ptr;
	}

};


}

#pragma pack(pop)
