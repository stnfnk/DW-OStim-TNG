Scriptname DW_VisualsSpellScr extends activemagiceffect

DW_CORE Property CORE Auto
Actor Property targetRef Auto Hidden

float strVisual

Event OnEffectStart(Actor akTarget, Actor akCaster)
  targetRef = akCaster  
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if !targetRef || !CORE
    return
  endif
  ; Use GameTime update to ensure initialization is complete
  RegisterForSingleUpdateGameTime(0.01)
EndEvent

Event OnUpdateGameTime()
  ; Now we're guaranteed to be initialized, switch to regular updates
  RegisterForSingleUpdate(1.0)
EndEvent

Event OnUpdate()
  if !targetRef || !CORE
    return
  endif
  if (CORE.DW_ModState05.GetValue() == 1 || CORE.DW_ModState07.GetValue() == 1)
    ; Check blindfold status - add null checks for external scripts
    if (!CORE.DDi || CORE.DDi.IsWearingDDBlindfold(targetRef) == false) && (!CORE.zbf || CORE.zbf.IsWearingZaZBlindfold(targetRef) == false) 
      if (CORE.DW_bAnimating.GetValue() == 1 && CORE.DW_ModState09.GetValue() != 1) || CORE.DW_bAnimating.GetValue() == 0
        float rank = CORE.SLA.GetActorArousal(targetRef)
        strVisual = rank / 100 ;effect strength
        ;visual high
        if CORE.DW_ModState05.GetValue() == 1 && rank >= CORE.DW_effects_heavy.GetValue() && CORE.HighArousalVisual
          CORE.HighArousalVisual.PopTo(CORE.HighArousalVisual, strVisual)
        elseif CORE.HighArousalVisual
          CORE.HighArousalVisual.Remove()
        endif
        ;visual low
        if CORE.DW_ModState07.GetValue() == 1 && rank >= CORE.DW_effects_light.GetValue() && CORE.LowArousalVisual
          CORE.LowArousalVisual.PopTo(CORE.LowArousalVisual, strVisual)
        elseif CORE.LowArousalVisual
          CORE.LowArousalVisual.Remove()
        endif
        if targetRef.HasSpell(CORE.DW_Visuals_Spell)
          RegisterForSingleUpdate(CORE.DW_SpellsUpdateTimer.GetValue())
          return
        endif
      endif
    endif
  endif
  targetRef.RemoveSpell(CORE.DW_Visuals_Spell)
EndEvent

Event OnPlayerLoadGame()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if !targetRef || !CORE
    return
  endif
  targetRef.RemoveSpell(CORE.DW_Visuals_Spell)
  ; Restart the update cycle with GameTime method
  RegisterForSingleUpdateGameTime(0.01)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  ; Safely remove visual effects
  if CORE
    if CORE.HighArousalVisual
      CORE.HighArousalVisual.Remove()
    endif
    if CORE.LowArousalVisual
      CORE.LowArousalVisual.Remove()
    endif
  endif
  targetRef = None
EndEvent
