Scriptname DW_HeartSpellScr extends activemagiceffect

DW_CORE Property CORE Auto
Actor Property targetRef Auto Hidden

Int Sound1ID = 0
Int Sound2ID = 0
float strSound

Event OnEffectStart(Actor akTarget, Actor akCaster)
  targetRef = akTarget
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
  if !targetRef || !targetRef.Is3DLoaded() || !targetRef.GetParentCell() || !CORE
    return
  endif
  Actor currentActor = targetRef
  if currentActor && CORE.DW_ModState06.GetValue() == 1    ;heartbeat sound enabled
    float rank = CORE.SLA.GetActorArousal(currentActor)
    if CORE.DW_ModState11.GetValue() == 0
      strSound = rank/100
    else
      strSound = 1
    endif
    if rank >= CORE.DW_effects_heavy.GetValue()            ;high arousal
      if Sound1ID != 0
        Sound.StopInstance(Sound1ID)
        Sound1ID = 0
      endif
      if Sound2ID == 0 && CORE.Heartbeat2
        Sound2ID = CORE.Heartbeat2.play(currentActor)
        if Sound2ID != 0
          Sound.SetInstanceVolume(Sound2ID, strSound)
        endif
      elseif Sound2ID != 0
        Sound.SetInstanceVolume(Sound2ID, strSound)
      endif
    elseif rank >= CORE.DW_effects_light.GetValue()        ;low arousal
      if Sound2ID != 0
        Sound.StopInstance(Sound2ID)
        Sound2ID = 0
      endif
      if Sound1ID == 0 && CORE.Heartbeat1
        Sound1ID = CORE.Heartbeat1.play(currentActor)
        if Sound1ID != 0
          Sound.SetInstanceVolume(Sound1ID, strSound)
        endif
      elseif Sound1ID != 0
        Sound.SetInstanceVolume(Sound1ID, strSound)
      endif
    else                                                   ;no arousal
      currentActor.RemoveSpell(CORE.DW_Heart_Spell)
      return
    endif
    if CORE.DW_bAnimating.GetValue() == 1 && CORE.DW_ModState10.GetValue() == 1
      if Sound1ID != 0
        Sound.StopInstance(Sound1ID)
        Sound1ID = 0
      endif
      if Sound2ID != 0
        Sound.StopInstance(Sound2ID)
        Sound2ID = 0 
      endif
    endif
    if currentActor.HasSpell(CORE.DW_Heart_Spell)
      float nextUpdate
      if currentActor == Game.GetPlayer()
        nextUpdate = CORE.DW_SpellsUpdateTimer.GetValue()
      else
        nextUpdate = CORE.DW_SpellsUpdateTimer.GetValue() + Utility.RandomInt(1,2)
      endif
      RegisterForSingleUpdate(nextUpdate)
      return
    endif
  endif
  if currentActor
    currentActor.RemoveSpell(CORE.DW_Heart_Spell)
  endif
EndEvent

Event OnPlayerLoadGame()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if !targetRef || !targetRef.Is3DLoaded() || !targetRef.GetParentCell() || !CORE
    return
  endif
  targetRef.RemoveSpell(CORE.DW_Heart_Spell)
  ; Restart the update cycle with GameTime method
  RegisterForSingleUpdateGameTime(0.01)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  if Sound1ID != 0
    Sound.StopInstance(Sound1ID)
    Sound1ID = 0
  endif
  if Sound2ID != 0
    Sound.StopInstance(Sound2ID)
    Sound2ID = 0
  endif
  targetRef = None
EndEvent
