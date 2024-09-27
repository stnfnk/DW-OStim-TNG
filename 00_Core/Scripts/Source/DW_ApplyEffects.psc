scriptname DW_ApplyEffects extends ActiveMagicEffect


DW_CORE CORE
DW_SL SL
DW_SLA SLA
DW_DDi DDi
DW_zbf zbf


Function OnEffectStart(Actor aNPC, Actor akCaster)
  CORE =Game.GetFormFromFile(0xA862, "DW.esp") as DW_CORE
  SLA = Game.GetFormFromFile(0xA87B, "DW.esp") as DW_SLA
  SL = Game.GetFormFromFile(0xA8B1, "DW.esp") as DW_SL
  DDi = Game.GetFormFromFile(0xA879, "DW.esp") as DW_DDi
  zbf = Game.GetFormFromFile(0xA87A, "DW.esp") as DW_zbf
  if (!aNPC || !CORE)
    Debug.Trace("[DW] Skipping OnEffectStart, not ready")
    return
  endif
  ; Do one update for actors the first time we enter a zone. Introduce a little jitter to distribute load.
  int updateTime = 2 + Utility.RandomInt(0, 5)
  RegisterForSingleUpdate(updateTime)
EndFunction


Event OnUpdate()
  actor aNPC = GetTargetActor()
  if !aNPC.Is3DLoaded()
    UnregisterForUpdate()
    return
  endif
  if aNPC != none
    if !CORE || !SLA || !SL
      debug.trace("DW failed to load script references")
      UnregisterForUpdate()
      return
    ;dripping wet npc
    elseif SLA.GetActorArousal(aNPC) >= CORE.DW_Arousal_threshold.GetValue()
      if CORE.DW_bUseSLGenderForDripp.GetValue() != 1\
      || (SL.GetGender( aNPC ) == 1 && aNPC.GetLeveledActorBase().GetSex() == 1 && CORE.DW_bUseSLGenderForDripp.GetValue() == 1)
        CORE.DW_Dripping_Spell.cast( aNPC )
      endif
    endif
    ;dripping gag npc
    if DDi.IsWearingDDGag(aNPC) || zbf.IsWearingZaZGag(aNPC)
      CORE.DW_DrippingGag_Spell.cast( aNPC )
    endif
    ;breath npc
    if CORE.DW_ModState00.GetValue() == 1 && !aNPC.HasSpell( CORE.DW_Breath_Spell ) && aNPC != game.GetPlayer()
      aNPC.AddSpell( CORE.DW_Breath_Spell, false )
    endif
    int updateTime = 2 + Utility.RandomInt(0, 5)
    RegisterForSingleUpdate(updateTime)
  endif
EndEvent