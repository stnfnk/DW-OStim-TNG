Scriptname DW_HeartSpellScr extends activemagiceffect

DW_CORE CORE

Actor akActor

Int Sound1ID = 0
Int Sound2ID = 0
float strSound

Event OnEffectStart(Actor akTarget, Actor akCaster)
  akActor = akTarget
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  RegisterForSingleUpdate(1)
EndEvent

Event OnUpdate()
  ; Add null check to prevent error
  if akActor == None
    return
  endif
  
  ;sound heartbeat high,low,none
  if CORE.DW_ModState06.GetValue() == 1                    ;heartbeat sound enabled
    float rank = CORE.SLA.GetActorArousal(akActor)
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
      if Sound2ID == 0
        Sound2ID = CORE.Heartbeat2.play(akActor)
        Sound.SetInstanceVolume(Sound2ID, strSound)
      else
        Sound.SetInstanceVolume(Sound2ID, strSound)
      endif
    elseif rank >= CORE.DW_effects_light.GetValue()        ;low arousal
      if Sound2ID != 0
        Sound.StopInstance(Sound2ID)
        Sound2ID = 0
      endif
      if Sound1ID == 0
        Sound1ID = CORE.Heartbeat1.play(akActor)
        Sound.SetInstanceVolume(Sound1ID, strSound)
      else
        Sound.SetInstanceVolume(Sound1ID, strSound)
      endif
    else                                                ;no arousal
      akActor.RemoveSpell(CORE.DW_Heart_Spell)
      return
    endif
    
    ; Add animation check which was missing in original
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
    
    if akActor.HasSpell(CORE.DW_Heart_Spell)
      if akActor && akActor.Is3DLoaded() && akActor.GetParentCell()
        RegisterForSingleUpdate(CORE.DW_SpellsUpdateTimer.GetValue())
        return
      else
        ; Actor isn't loaded in 3D or has no parent cell - don't try to update
        return
      endif
    endif
  endif
  akActor.RemoveSpell(CORE.DW_Heart_Spell)
EndEvent

Event OnPlayerLoadGame()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if akActor != None
    akActor.RemoveSpell(CORE.DW_Heart_Spell)
  endif
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  if Sound1ID != 0
    Sound.StopInstance(Sound1ID)
  endif
  if Sound2ID != 0
    Sound.StopInstance(Sound2ID)
  endif
EndEvent
