Scriptname DW_BreathSpellScr extends activemagiceffect

DW_CORE CORE

Actor akActor

Int Sound1ID = 0
Int Sound2ID = 0
Sound Sound1
Sound Sound2
float strSound

Event OnEffectStart( Actor akTarget, Actor akCaster )
	akActor = akTarget
	CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
	RegisterForSingleUpdate(1)
EndEvent

Event OnUpdate()
  akActor.ResetExpressionOverrides()
	;sound Breath high,low,none
	;CORE.sexlab.Log(Sound1ID+" Breath cycle start "+Sound2ID)
	if akActor != None && (CORE.DW_ModState08.GetValue() == 1 && akActor == Game.GetPlayer()) || (CORE.DW_ModState00.GetValue() == 1 && akActor != Game.GetPlayer())
		float rank = CORE.SLA.GetActorArousal(akActor)
		if CORE.DW_ModState12.GetValue() == 0
			strSound = rank/100
		else
			strSound = 1
		endif
		
		if akActor.GetLeveledActorBase().GetSex() == 1		;female
			Sound1 = CORE.Breathing1
			Sound2 = CORE.Breathing2
		elseif akActor.GetLeveledActorBase().GetSex() == 0	;male
			Sound1 = CORE.Breathing3
			Sound2 = CORE.Breathing4
		else												;no beasts
			akActor.RemoveSpell(CORE.DW_Breath_Spell)
			return
		endif

		if  rank >= CORE.DW_effects_heavy.GetValue()		;high arousal
      BreathAnim(akActor,11,55,85)
			if Sound1ID != 0
				;CORE.sexlab.Log(Sound1ID+" Breath1 stop")
				Sound.StopInstance(Sound1ID)
				Sound1ID = 0
			endif
			if Sound2ID == 0
				Sound2ID = Sound2.play(akActor)
				;CORE.sexlab.Log(Sound2ID+" Breath2 start")
				Sound.SetInstanceVolume(Sound2ID, strSound)
			else
				;CORE.sexlab.Log(Sound2ID+" Breath2 update")
				Sound.SetInstanceVolume(Sound2ID, strSound)
			endif
      
		elseif rank >= CORE.DW_effects_light.GetValue()		;low arousal
      BreathAnim(akActor,11,50,70)
			if Sound2ID != 0
				;CORE.sexlab.Log(Sound2ID+" Breath2 stop")
				Sound.StopInstance(Sound2ID)
				Sound2ID = 0
			endif
			if Sound1ID == 0
				Sound1ID = Sound1.play(akActor)
				;CORE.sexlab.Log(Sound1ID+" Breath1 start")
				Sound.SetInstanceVolume(Sound1ID, strSound)
			else
				;CORE.sexlab.Log(Sound1ID+" Breath1 update")
				Sound.SetInstanceVolume(Sound1ID, strSound)
			endif
		else												;no arousal
			;CORE.sexlab.Log("Arousal too low, Breathing effect stopping " +Sound1ID + " | " + Sound2ID)
      akActor.ResetExpressionOverrides()
			akActor.RemoveSpell(CORE.DW_Breath_Spell)
			return
		endif
		if akActor.HasSpell(CORE.DW_Breath_Spell)
			RegisterForSingleUpdate(CORE.DW_SpellsUpdateTimer.GetValue())
			return
		endif
	endif
  akActor.ResetExpressionOverrides()
	akActor.RemoveSpell(CORE.DW_Breath_Spell)
EndEvent

Event OnPlayerLoadGame()
	CORE = Game.GetFormFromFile(0x862, "DW.esp") as DW_CORE
	;CORE.sexlab.Log("OnPlayerLoadGame(), Breathing effect stopping ")
  akActor.ResetExpressionOverrides()
	akActor.RemoveSpell(CORE.DW_Breath_Spell)
EndEvent

Event OnEffectFinish( Actor akTarget, Actor akCaster )
  akActor.ResetExpressionOverrides()
	if Sound1ID != 0
		Sound.StopInstance(Sound1ID)
		;CORE.sexlab.Log("Breath1 removed")
	endif
	if Sound2ID != 0
		Sound.StopInstance(Sound2ID)
		;CORE.sexlab.Log("Breath2 removed")
	endif
EndEvent

Function BreathAnim(actor mouthBreather, int phoneme, int min, int max)
  int i = min

  while i < max
    MfgConsoleFunc.SetPhoneMe(mouthBreather, phoneme ,i)
    i = i + 6
  if (i > max)
    i = max
  Endif
    Utility.Wait(0.0005)
  endwhile

  Utility.Wait(0.7)

  while i > min
    MfgConsoleFunc.SetPhoneMe(mouthBreather, phoneme ,i)
    i = i - 3
    if (i < min)
      i = min
    Endif
    Utility.Wait(0.0005)
    endwhile
EndFunction