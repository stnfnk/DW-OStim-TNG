scriptname DW_ApplyEffects extends ActiveMagicEffect


DW_CORE CORE
DW_SL SL
DW_SLA SLA
DW_DDi DDi
DW_zbf zbf


Function OnEffectStart(Actor aNPC, Actor akCaster)
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  SLA = Game.GetFormFromFile(0x87B, "DW.esp") as DW_SLA
  SL = Game.GetFormFromFile(0x8B1, "DW.esp") as DW_SL
  DDi = Game.GetFormFromFile(0x879, "DW.esp") as DW_DDi
  zbf = Game.GetFormFromFile(0x87A, "DW.esp") as DW_zbf
  if (!aNPC || !CORE)
    Debug.Trace("[DW] Skipping OnEffectStart, not ready")
    return
  endif
  if self && self as ActiveMagicEffect
    ; Do one update for actors the first time we enter a zone. Introduce a little jitter to distribute load.
    int updateTime = 2 + Utility.RandomInt(0, 5)
    RegisterForSingleUpdate(updateTime)
  else
    Debug.Trace("[DW_ApplyEffects] Failed to register for update - invalid script state")
  endif
EndFunction


Event OnUpdate()
  actor aNPC = GetTargetActor()
  if !aNPC || !aNPC.Is3DLoaded()
    UnregisterForUpdate()
    return
  elseif !CORE || !SLA || !SL  ; Fixed: Added validation for required scripts
    Debug.Trace("[DW_ApplyEffects] Missing core script references")
    UnregisterForUpdate()
    return
  endif
  ; Process dripping effects
  if SLA.GetActorArousal(aNPC) >= CORE.DW_Arousal_threshold.GetValue()
    if CORE.DW_bUseSLGenderForDripp.GetValue() != 1\
    || (SL.GetGender(aNPC) == 1 && aNPC.GetLeveledActorBase().GetSex() == 1 && CORE.DW_bUseSLGenderForDripp.GetValue() == 1)
      CORE.DW_Dripping_Spell.cast(aNPC)
    endif
  endif
  
  ; Process gag effects
  if DDi && zbf && (DDi.IsWearingDDGag(aNPC) || zbf.IsWearingZaZGag(aNPC))
    if CORE.DW_DrippingGag_Spell
      CORE.DW_DrippingGag_Spell.cast(aNPC)
    endif
  endif
  
  ; Process breath effects
  if CORE.DW_ModState00 && CORE.DW_Breath_Spell && CORE.DW_ModState00.GetValue() == 1 && !aNPC.HasSpell(CORE.DW_Breath_Spell) && aNPC != game.GetPlayer()
    aNPC.AddSpell(CORE.DW_Breath_Spell, false)
  endif
  
  ; Schedule next update with safety check
  if self && self as ActiveMagicEffect
    int updateTime = 2 + Utility.RandomInt(0, 5)
    RegisterForSingleUpdate(updateTime)
  else
    Debug.Trace("[DW_ApplyEffects] Failed to register for next update - invalid script state")
  endif
EndEvent