Scriptname DW_BreathSpellScr extends activemagiceffect

DW_CORE Property CORE Auto

Actor Property targetRef Auto Hidden

; Sound related variables
Int Sound1ID = 0
Int Sound2ID = 0
Sound Sound1
Sound Sound2
float strSound = 0.0

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
  ; Early validation checks
  if !targetRef || !targetRef.Is3DLoaded() || !targetRef.GetParentCell()
    return
  endif
  ; Validate CORE reference first
  if !CORE
    CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
    if !CORE
      Debug.Trace("DW_BreathSpellScr - CORE reference is None")
      return
    endif
  endif
  Actor currentActor = targetRef
  if currentActor
    ; Validate GlobalVariables before using
    bool playerBreathEnabled = false
    if CORE.DW_ModState08
      playerBreathEnabled = (CORE.DW_ModState08.GetValue() == 1)
    else
      Debug.Trace("DW_BreathSpellScr - DW_ModState08 is None")
      return
    endif
    bool npcBreathEnabled = false
    if CORE.DW_ModState00
      npcBreathEnabled = (CORE.DW_ModState00.GetValue() == 1)
    else
      Debug.Trace("DW_BreathSpellScr - DW_ModState00 is None")
      return
    endif
    bool isPlayer = (currentActor == Game.GetPlayer())
    if (playerBreathEnabled && isPlayer) || (npcBreathEnabled && !isPlayer)
      ; Validate SLA before using
      if !CORE.SLA
        Debug.Trace("DW_BreathSpellScr - SLA is None")
        return
      endif
      float rank = CORE.SLA.GetActorArousal(currentActor)
      ; Sound volume setting - using CLASS LEVEL variable
      if CORE.DW_ModState12 && CORE.DW_ModState12.GetValue() == 0
        strSound = rank/100
      else
        strSound = 1
      endif
      ; Sex-based sound selection - use CLASS LEVEL variables
      int sex = currentActor.GetLeveledActorBase().GetSex()
      if sex == 1  ; female
        Sound1 = CORE.Breathing1
        Sound2 = CORE.Breathing2
      elseif sex == 0  ; male
        Sound1 = CORE.Breathing3
        Sound2 = CORE.Breathing4
      else  ; no beasts
        if CORE.DW_Breath_Spell && currentActor.HasSpell(CORE.DW_Breath_Spell)
          currentActor.RemoveSpell(CORE.DW_Breath_Spell)
        endif
        return
      endif
      ; Check arousal thresholds (validate globals first)
      if !CORE.DW_effects_heavy || !CORE.DW_effects_light
        Debug.Trace("DW_BreathSpellScr - Missing arousal threshold globals")
        return
      endif
      float heavyThreshold = CORE.DW_effects_heavy.GetValue()
      float lightThreshold = CORE.DW_effects_light.GetValue()
      if rank >= heavyThreshold  ; high arousal
        if Sound1ID != 0
          Sound.StopInstance(Sound1ID)
          Sound1ID = 0
        endif
        if Sound2ID == 0 && Sound2
          Sound2ID = Sound2.play(currentActor)
          Sound.SetInstanceVolume(Sound2ID, strSound)
        elseif Sound2ID != 0
          Sound.SetInstanceVolume(Sound2ID, strSound)
        endif
      elseif rank >= lightThreshold  ; low arousal
        if Sound2ID != 0
          Sound.StopInstance(Sound2ID)
          Sound2ID = 0
        endif
        if Sound1ID == 0 && Sound1
          Sound1ID = Sound1.play(currentActor)
          Sound.SetInstanceVolume(Sound1ID, strSound)
        elseif Sound1ID != 0
          Sound.SetInstanceVolume(Sound1ID, strSound)
        endif
      else  ; no arousal
        if CORE.DW_Breath_Spell && currentActor.HasSpell(CORE.DW_Breath_Spell)
          currentActor.RemoveSpell(CORE.DW_Breath_Spell)
        endif
        return
      endif
      ; Animation state check (mute during animations if configured)
      if CORE.DW_bAnimating && CORE.DW_ModState10 && CORE.DW_bAnimating.GetValue() == 1 && CORE.DW_ModState10.GetValue() == 1
        if Sound1ID != 0
          Sound.StopInstance(Sound1ID)
          Sound1ID = 0
        endif
        if Sound2ID != 0
          Sound.StopInstance(Sound2ID)
          Sound2ID = 0 
        endif
      endif
      ; Schedule next update if spell still active
      if CORE.DW_Breath_Spell && currentActor.HasSpell(CORE.DW_Breath_Spell)
        float nextUpdate = 1.0
        if CORE.DW_SpellsUpdateTimer
          if isPlayer
            nextUpdate = CORE.DW_SpellsUpdateTimer.GetValue()
          else
            nextUpdate = CORE.DW_SpellsUpdateTimer.GetValue() + Utility.RandomInt(1,2)
          endif
        endif
        RegisterForSingleUpdate(nextUpdate)
        return
      endif
    endif
    ; Remove spell if we reach this point (conditions no longer met)
    if currentActor && CORE.DW_Breath_Spell && currentActor.HasSpell(CORE.DW_Breath_Spell)
      currentActor.RemoveSpell(CORE.DW_Breath_Spell)
    endif
  endif
EndEvent

Event OnPlayerLoadGame()
  CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
  if !targetRef || !targetRef.Is3DLoaded() || !targetRef.GetParentCell() || !CORE || !CORE.DW_Breath_Spell
    return
  endif
  targetRef.RemoveSpell(CORE.DW_Breath_Spell)
  ; Restart the update cycle with GameTime method
  RegisterForSingleUpdateGameTime(0.01)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  ; Clear the sound instances on finish
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
