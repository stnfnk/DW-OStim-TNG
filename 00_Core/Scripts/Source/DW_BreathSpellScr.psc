Scriptname DW_BreathSpellScr extends activemagiceffect

DW_CORE CORE

Actor akActor

Int Sound1ID = 0
Int Sound2ID = 0
Sound Sound1
Sound Sound2
float strSound

Event OnEffectStart(Actor akTarget, Actor akCaster)
  akActor = akTarget
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if akActor && CORE
    RegisterForSingleUpdate(1)
  endif
EndEvent

Event OnUpdate()
  ; Simple check to avoid errors
  if akActor == None || CORE == None
    return
  endif
  
  ; Store the actor reference in a local variable to keep it consistent
  Actor currentActor = akActor
  
  ; The main logic - only if the actor is valid
  if currentActor
    if (CORE.DW_ModState08.GetValue() == 1 && currentActor == Game.GetPlayer()) || (CORE.DW_ModState00.GetValue() == 1 && currentActor != Game.GetPlayer())
      float rank = CORE.SLA.GetActorArousal(currentActor)
      if CORE.DW_ModState12.GetValue() == 0
        strSound = rank/100
      else
        strSound = 1
      endif
      
      if currentActor.GetLeveledActorBase().GetSex() == 1        ;female
        Sound1 = CORE.Breathing1
        Sound2 = CORE.Breathing2
      elseif currentActor.GetLeveledActorBase().GetSex() == 0    ;male
        Sound1 = CORE.Breathing3
        Sound2 = CORE.Breathing4
      else                                                ;no beasts
        currentActor.RemoveSpell(CORE.DW_Breath_Spell)
        return
      endif

      if rank >= CORE.DW_effects_heavy.GetValue()        ;high arousal
        if Sound1ID != 0
          Sound.StopInstance(Sound1ID)
          Sound1ID = 0
        endif
        if Sound2ID == 0
            Sound2ID = Sound2.play(currentActor)
            Sound.SetInstanceVolume(Sound2ID, strSound)
        else
            Sound.SetInstanceVolume(Sound2ID, strSound)
        endif    
      elseif rank >= CORE.DW_effects_light.GetValue()    ;low arousal
        if Sound2ID != 0
            Sound.StopInstance(Sound2ID)
            Sound2ID = 0
        endif
        if Sound1ID == 0
            Sound1ID = Sound1.play(currentActor)
            Sound.SetInstanceVolume(Sound1ID, strSound)
        else
            Sound.SetInstanceVolume(Sound1ID, strSound)
        endif
      else                                                ;no arousal
        currentActor.RemoveSpell(CORE.DW_Breath_Spell)
        return
      endif
      
      ; Check for animation states
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
      
      ; Only try to register for update if the spell is still active
      if currentActor.HasSpell(CORE.DW_Breath_Spell)
        if akActor && akActor.Is3DLoaded() && akActor.GetParentCell()
          RegisterForSingleUpdate(CORE.DW_SpellsUpdateTimer.GetValue())
          return
        else
          ; Actor isn't loaded in 3D or has no parent cell - don't try to update
          return
        endif
      endif
    endif
    ; If we got here, we should remove the spell
    currentActor.RemoveSpell(CORE.DW_Breath_Spell)
  endif
EndEvent

Event OnPlayerLoadGame()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if akActor != None && CORE != None
    akActor.RemoveSpell(CORE.DW_Breath_Spell)
  endif
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  ; Clear the sound instances on finish
  if Sound1ID != 0
    Sound.StopInstance(Sound1ID)
  endif
  if Sound2ID != 0
    Sound.StopInstance(Sound2ID)
  endif
EndEvent